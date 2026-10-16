---
title: The same pipeline as a state machine
version: 1
---

**Step Functions runs a pipeline written as a state machine**: a JSON document of states, each
naming what it does and which state comes next. A `Task` state calls a service, and with the suffix
`.sync` on its resource it waits for the call to finish, so a state that starts a Glue job moves on
only when the job has succeeded. Nothing runs between executions and nothing is billed between them:
Standard workflows are charged per state transition, and a pipeline of two states run once a night
makes a few transitions a night. The price sheet of this course has no line for Step Functions, so
this lesson quotes no number for it.

Here is the DAG of the first section again, as a state machine. Save it as `nightly.json`:

`nightly.json`:

```json
{
  "Comment": "Quitanda's nightly orders: load the day, then build the daily table",
  "StartAt": "LoadOrders",
  "States": {
    "LoadOrders": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "load-orders",
        "Arguments": {"--scheduled.$": "$.scheduled"}
      },
      "Retry": [{"ErrorEquals": ["States.ALL"], "IntervalSeconds": 300, "MaxAttempts": 2}],
      "Next": "BuildDaily"
    },
    "BuildDaily": {
      "Type": "Task",
      "Resource": "arn:aws:states:::glue:startJobRun.sync",
      "Parameters": {
        "JobName": "build-daily",
        "Arguments": {"--scheduled.$": "$.scheduled"}
      },
      "Retry": [{"ErrorEquals": ["States.ALL"], "IntervalSeconds": 300, "MaxAttempts": 2}],
      "End": true
    }
  }
}
```

**Read it against the DAG and the two line up one for one.** `load_orders` is `LoadOrders`, the
`>>` is `"Next": "BuildDaily"`, and `retries=2` five minutes apart is the `Retry` on each state, two
attempts 300 seconds apart. The `.$` at the end of `--scheduled.$` tells Step Functions to take the
value from the execution's input, at the path `$.scheduled`, instead of passing the text literally.

**What has no counterpart is `{{ ds }}`.** Airflow knew which interval a run covered; a state machine
knows only what it was given. Here it is given a timestamp, the moment the schedule fired, and the
Glue job has to work out "yesterday" from it. There is no backfill either: re-running the 12th means
starting an execution by hand with the timestamp of the 13th in its input. For a pipeline that
runs every night and is rarely re-run, that is a fair trade; for one that is re-run often, it is the
first thing that hurts.

## Created, started, and run by nobody

Create the state machine, start it once by hand, and look at the execution:

```
ana@laptop:~/aws$ aws stepfunctions create-state-machine --name quitanda-nightly --definition file://nightly.json --role-arn arn:aws:iam::123456789012:role/quitanda-sfn
{
    "stateMachineArn": "arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly",
    "creationDate": "2026-10-16T13:07:38.607000-03:00"
}
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly --input '{"scheduled": "2026-10-16T03:00:00-03:00"}'
{
    "executionArn": "arn:aws:states:sa-east-1:123456789012:execution:quitanda-nightly:e6b6b224-06f7-4233-8f76-5f9f1e0d851c",
    "startDate": "2026-10-16T13:07:39.229000-03:00"
}
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn arn:aws:states:sa-east-1:123456789012:execution:quitanda-nightly:e6b6b224-06f7-4233-8f76-5f9f1e0d851c --query '[status,input,output]'
[
    "RUNNING",
    "{\"scheduled\": \"2026-10-16T03:00:00-03:00\"}",
    null
]
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn arn:aws:states:sa-east-1:123456789012:execution:quitanda-nightly:e6b6b224-06f7-4233-8f76-5f9f1e0d851c --query 'events[].type'
[
    "ExecutionStarted",
    "PassStateEntered",
    "PassStateExited",
    "ExecutionSucceeded"
]
ana@laptop:~/aws$ aws glue get-job-runs --job-name load-orders

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetJobRuns operation: Job load-orders not found.
```

**moto contradicts itself, and both halves are worth reading.** `describe-execution` says the
execution is `RUNNING`, and it will stay so: moto does not execute state machines, so nothing ever
moves it on. `get-execution-history` says the opposite, that the execution started, entered a
`Pass` state, left it, and succeeded. There is no `Pass` state in `nightly.json`. That history is a
fixed sample moto returns for any execution, the same four events whatever the definition says, and
it describes nothing that happened.

**The last command settles it.** The state machine was supposed to start the Glue job `load-orders`,
and Glue has never heard of it: there is no such job in this moto, and none was run. So the lab shows
the definition, stored and returned exactly as written, and the request to start it, well formed.
How Step Functions waits on a `.sync` task, retries it and fails the execution after the second
attempt is AWS's documented behaviour, and none of it was run here.
