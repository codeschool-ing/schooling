---
title: "Waiting: a timer, a callback and a job"
version: 1
---

Long-running orchestration sounds as if something must be running for a long time. **Nothing is.**
A Standard execution that waits three days for a warehouse costs what its transitions cost, and no
process of yours stays up for any of it. Step Functions has three ways to wait, and they differ in
who decides when the wait is over: a clock, somebody who holds a token, or the job the state
started.

## A clock: Wait

The `Wait` state of the order machine waited two seconds. It can also wait until a moment, with
`Timestamp`, or for a number or a date taken from the input, with `SecondsPath` and
`TimestampPath`: a reminder sent at the hour a customer chose is one `Wait` with a
`TimestampPath`. On a Standard workflow the state counts as transitions like any other, and the
time spent in it is free, so **a wait of a week costs the same as a wait of a second**. An Express
workflow cannot wait past its five minutes.

## Somebody with a token: .waitForTaskToken

Some work finishes when a person or another system says so: a store confirms it has picked an
order, a manager approves a refund. The task hands out a token and the execution waits until the
token comes back. Save the file as `~/aws/token.asl.json`:

```schooling-example
{"language": "json", "file": "token.asl.json", "parts": [{"code": "{\n  \"StartAt\": \"AskStore\",\n  \"States\": {\n    \"AskStore\": {\n      \"Type\": \"Task\",\n      \"Resource\": \"arn:aws:states:::sqs:sendMessage.waitForTaskToken\",\n", "note": "The suffix `.waitForTaskToken` changes what the task waits for: it sends the message and then waits for somebody to say the work is done, however long that takes."}, {"code": "      \"Parameters\": {\n        \"QueueUrl\": \"https://sqs.sa-east-1.amazonaws.com/123456789012/store\",\n        \"MessageBody\": {\"order.$\": \"$.id\", \"token.$\": \"$$.Task.Token\"}\n      },\n", "note": "`$$` reads the context rather than the input, and `$$.Task.Token` is the token of this one wait. It travels inside the message, because whoever finishes the work has to hand it back."}, {"code": "      \"TimeoutSeconds\": 86400,\n      \"End\": true\n    }\n  }\n}\n", "note": "Without a timeout, a token nobody returns keeps the execution waiting for as long as a Standard execution may live, which is a year. A day is the upper bound here."}]}
```

Ana starts it, and the store's side of the conversation is played by hand at the prompt: read the
request from the queue and report success with the token it carries:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name store --query QueueUrl --output text
http://localhost:4567/123456789012/store
ana@laptop:~/aws$ TOKEN_SM=$(aws stepfunctions create-state-machine --name ask-store --definition file://token.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$TOKEN_SM" --name order-46 --input '{"id": "46"}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:ask-store:order-46
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query status
"RUNNING"
ana@laptop:~/aws$ MSG=$(aws sqs receive-message --queue-url https://sqs.sa-east-1.amazonaws.com/123456789012/store --query "Messages[0].Body" --output text); echo "$MSG"
{"order": "46", "token": "57190edc-1fda-4e90-8701-408ad3fc2252"}
```

**The execution sat in `RUNNING` with nothing running.** The message carries the order and the
token, and that is all the store needs. Now it answers:

```
ana@laptop:~/aws$ aws stepfunctions send-task-success --task-token "$(echo "$MSG" | jq -r .token)" --task-output '{"picked": true}'
ana@laptop:~/aws$ sleep 1
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query "{status: status, output: output}"
{
    "status": "SUCCEEDED",
    "output": "{\"picked\": true}"
}
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${TOKEN_SM/stateMachine/execution}:order-46" --query "events[].type" --output text
ExecutionStarted	TaskStateEntered	TaskScheduled	TaskStarted	TaskSubmitted	TaskSucceeded	TaskStateExited	ExecutionSucceeded
```

`send-task-success` is the store saying it is done, and its `--task-output` becomes the task's
result. In the history, `TaskSubmitted` is the moment the message went out and `TaskSucceeded`
the moment the token came back; between the two, the execution held nothing but its place. The other two calls a worker can make are `send-task-failure`, with an error and a cause,
which the state's `Retry` and `Catch` then handle as any task failure, and `send-task-heartbeat`,
which matters when the state sets `HeartbeatSeconds`: a worker that goes quiet for longer than
that fails the task with `States.HeartbeatTimeout`, so a crashed worker is noticed in minutes
instead of at the end of a day-long `TimeoutSeconds`.

moto's token is a UUID. **AWS's token is a long opaque string, up to 1,024 characters**, and the
only thing to do with it is store it whole and hand it back; nothing in it is meant to be read.

## The job itself: .sync

The third way is for work that another AWS service runs and knows the end of. A task whose
resource ends in `.sync`, such as `arn:aws:states:::ecs:runTask.sync` for an ECS task from lesson
8 or `arn:aws:states:::states:startExecution.sync:2` for a child state machine, starts the job
and then waits until the job ends, and the task's result is the job's outcome. Without `.sync` the
same resource starts the job and moves on at once, which is right when nobody needs the result.

**This part was not run.** moto has no ECS task to wait for, since it runs no container, and the
lesson does not lean on whatever its interpreter would do with one. On AWS, Step Functions follows
the job itself, with events where the service offers them and by polling where it does not, and
a `.sync` task is billed as transitions like any other; the wait is free here too. Like
`.waitForTaskToken`, it exists only in Standard workflows.

## Which wait, for which work

- A known time, or a time in the input: `Wait`.
- A person, or a system outside AWS that will call back: `.waitForTaskToken`, with a
  `TimeoutSeconds` that says how long is too long and, for a worker that can crash, a
  `HeartbeatSeconds`.
- A job in ECS, Batch, Glue, CodeBuild or another state machine: `.sync`.

The case for doing any of this in a state machine rather than in a function is the one lesson 19
ended with. A request that starts a job of minutes answers at once with an execution's name, and
the client asks `describe-execution` later, or is told through the queue and topic of lesson 21.
The waiting itself happens in the one place built to remember it.
