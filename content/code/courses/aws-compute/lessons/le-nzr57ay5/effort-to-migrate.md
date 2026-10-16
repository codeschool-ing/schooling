---
title: What the move costs, which no price list shows
version: 1
---

The cheapest column in the previous section is a price for running the workload once it is there.
**Getting it there is a second bill, paid in engineering time**, and it is often larger than a
year of the difference. A service that saves 20 USD a month by moving to Lambda and needs six weeks
of rework to get there has bought the saving at a price nobody would sign for in writing.

What makes a move expensive is almost never the code that answers a request. It is what the code
quietly assumes about the place it runs.

## Five assumptions that do not travel

**A disk of its own.** A program on an instance writes uploads, caches and reports to its file
system and finds them there tomorrow. A Fargate task's storage is ephemeral, 20 GB by default, and
goes with the task (lesson 9). A function's `/tmp` is 512 MB unless you configure more, up to
10,240 MB according to the API's own documentation, and it lasts only as long as one execution
environment. Moving off the instance means finding every write and sending it to S3, EFS or a
database first.

**Memory that outlives a request.** Sessions kept in the process, an in-memory cache, a counter.
On two instances behind a load balancer they already half work; on Lambda each concurrent request
may land in a different environment, and an environment can disappear at any time. They have to
move to a shared store before the code can move at all.

**A process that runs for a long time.** A function stops at its timeout, and the API's
documentation for `create-function` gives the limit: **900 seconds, fifteen minutes**, with a
default of 3. A report that takes twenty minutes does not run on Lambda as written; it has to be
cut into pieces, run on a Fargate task, or orchestrated by Step Functions (lesson 20).

**A request that waits a long time.** Behind API Gateway, the integration has its own limit, and
it is shorter. The documentation that ships with the command line says an HTTP API integration
times out between 50 and 30,000 milliseconds, **30 seconds at most**; a REST API defaults to 29
seconds, which can be raised only for Regional and private APIs. An endpoint that builds a
45-second export synchronously has to become a job: accept the request, put it on a queue
(lesson 21), and let the client collect the result.

**A connection that stays open.** A pool of 20 database connections per instance is 40 for two
instances. On Lambda every concurrent environment opens its own, and at the concurrency lesson 16
computed the database is the first thing to fall over.

## moto accepts what AWS refuses

None of those limits can be learnt from moto, because moto does not enforce them. Asked for a
function with a timeout one second past the limit, it creates one:

```
ana@laptop:~/aws$ aws lambda create-function --function-name report --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/report --zip-file fileb://app.zip --timeout 901 --query "[FunctionName, Timeout]"
[
    "report",
    901
]
```

`app.zip` holds a two-line `app.py`, a handler that returns `{"ok": True}`, and nothing
else. Asked for an HTTP API integration that waits two minutes, moto records that as well:

```
ana@laptop:~/aws$ API=$(aws apigatewayv2 create-api --name shop --protocol-type HTTP --query ApiId --output text)
ana@laptop:~/aws$ aws apigatewayv2 create-integration --api-id "$API" --integration-type AWS_PROXY --integration-uri arn:aws:lambda:sa-east-1:123456789012:function:report --payload-format-version 2.0 --timeout-in-millis 120000 --query "[IntegrationType, TimeoutInMillis]"
[
    "AWS_PROXY",
    120000
]
```

**AWS refuses both calls**, and neither refusal was run here, so this lesson quotes no error text
for them. The lesson to take is about checking, not about moto: a limit you have only met in an
imitation is a limit you have not met. Read it in the service's documentation, and when in doubt
in the command line's own model of the API, which is where the two numbers above come from.

## A table of moves

The same assumptions give a rough cost for each move, before a line of code is read:

| move | what usually has to change |
| --- | --- |
| EC2 → Fargate | build an image (`docker` course); local files to S3 or EFS; configuration into the task definition |
| EC2 → Lambda | everything above, plus sessions and caches out of memory, long jobs split, connections pooled outside the function |
| Fargate → Lambda | long requests turned into jobs; the server process replaced by a handler, or by an adapter that wraps one |
| Lambda → Fargate | a server process around the handlers; scaling rules of your own; a load balancer in front |
| App Runner → ECS | a task definition, a service and a load balancer, from the same image |

**Moves towards Lambda cost the most**, because a function assumes the least about where it
runs. Moves away from it are cheaper than they look: a handler is a function, and wrapping it in a
small web server is a day's work rather than a quarter's. That asymmetry is worth knowing before
the first line is written, and lesson 24 turns it into a decision.
