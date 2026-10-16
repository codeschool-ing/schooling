---
title: Standard and Express
version: 1
---

A state machine has a type, chosen when it is created and never changed afterwards. The two types
read the same Amazon States Language, which makes them look like one product with a speed
setting. **They are two engines with different promises**: a Standard workflow is a durable record
of one run that may last a year, and an Express workflow is a fast, cheap run of at most five
minutes that the service does not remember. Choosing between them is choosing which promise the
work needs.

## What each one promises

| | Standard | Express |
|---|---|---|
| longest run | one year | five minutes |
| how often a run happens | exactly once | at least once (started asynchronously) or at most once (synchronously) |
| history | kept by the service, readable for 90 days after the run | none in the service; sent to CloudWatch Logs if you turn logging on |
| `.waitForTaskToken` and `.sync` | yes | no |
| priced by | state transition | request, and duration by memory |

**"Exactly once" is about the workflow, not about your task.** A Standard execution never runs the
same state twice by accident; a `Retry` you wrote runs it again on purpose, and the next section is
about what that means for the task. An asynchronous Express execution can run twice for one start,
so every step in it has to be safe to repeat. The history row is the one people meet first: the
`get-execution-history` calls of the previous section have no Express equivalent, and an Express
run that failed and was not logged leaves nothing to read.

## moto keeps one engine

moto accepts the type and forgets it:

```
ana@laptop:~/aws$ aws stepfunctions create-state-machine --name orders-fast --type EXPRESS --definition file://split.asl.json --role-arn "$ROLE" --query stateMachineArn --output text
arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast
ana@laptop:~/aws$ aws stepfunctions describe-state-machine --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast --query type
"STANDARD"
ana@laptop:~/aws$ aws stepfunctions start-sync-execution --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:orders-fast --input '{"lines": []}'

aws: [ERROR]: Could not connect to the endpoint URL: "http://sync-localhost:4567/"
```

**On AWS, `describe-state-machine` answers `EXPRESS` here.** moto runs every state machine with
its one interpreter, which behaves as a Standard workflow does: history, durations of any length,
task tokens. So in the lab an Express machine will happily wait for an hour, which AWS would stop
at five minutes. The failed `start-sync-execution` is the command line's doing: it sends a
synchronous start to a host whose name begins with `sync-`, which on AWS is
`sync-states.sa-east-1.amazonaws.com` and here does not exist. A synchronous Express execution
returns the output in the same call, and it is how an API Gateway route waits for a short workflow
in one request.

## Two price models

The sheet printed both on 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py integration | sed -n 9,12p
Step Functions
  Standard, state transitions                       37.5  per million
  Express, requests                                    1  per million
  Express, duration (first tier)              0.00001667  per GB-second
```

A **state transition** is counted every time an execution enters a state, including each retry.
Ana's order workflow in production has ten steps, and the shop handles a million orders a month.
As Standard workflows that is 1,000,000 × 10 = 10,000,000 transitions, so 10 × 37.5 = 375.00 USD a
month. The 4,000 transitions a month that AWS gives free are left out of the arithmetic; they
would make no visible difference.

As Express workflows, each order is one request and a duration. **Express bills memory in steps of
64 MB and time rounded up to the next 100 ms**, and a workflow that only calls services needs no
more than the smallest step. At 2 seconds each, a million runs are
1,000,000 × 2 s × 0.0625 GB = 125,000 GB-seconds, so 125,000 × 0.00001667 = 2.08 USD of duration
plus 1 × 1 = 1.00 USD of requests: 3.08 USD a month. AWS's first duration tier covers the first
1,000 GB-hours of a month, and 125,000 GB-seconds is about 35, so the sheet's price applies to all
of it.

**375 against 3.08 is a factor of about 120, and it is not the whole decision.** The Express
price buys five minutes, no history and runs that may repeat. If a step of the order workflow
charges a card, a run that repeats charges it twice unless that step is idempotent. If any step
waits for a person, the warehouse or a cancel window of thirty minutes, the run outlives five
minutes and Express cannot hold it.

## Which one, then

**Standard for the long and the important; Express for the short and the many.** An order that
waits for a warehouse, a refund that needs an approval, a nightly job that runs for an hour:
Standard, and the price per transition is small against what each run is worth. Turning every
image that lands in S3 into three thumbnails, or validating and routing a hundred thousand events
a minute: Express, where the price per transition would dominate and each run is cheap to repeat.

A common shape uses both: a Standard workflow for the order as a whole, and an Express workflow
started from inside it for a burst of short steps, so the expensive meter counts one transition
for the burst instead of hundreds.
