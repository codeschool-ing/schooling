---
title: Errors, retries and the task that runs twice
version: 1
---

The first instinct with a failing step is to wrap it in a `try` and log the error. In a state
machine **the error handling is part of the document**: a `Retry` says which errors to try again,
how often and how far apart, and a `Catch` says where the execution goes when the retries run
out. The service applies both, records each attempt in the history, and keeps your task code free
of loops and sleeps.

## An error has a name

Every failure in an execution carries an error name and a cause. A task that fails reports the
error of the service it called. Step Functions adds names of its own, all beginning with
`States.`: `States.Timeout` when a task outlives its `TimeoutSeconds`, `States.TaskFailed` for any
task failure, `States.Permissions` when the role may not make the call. **`States.ALL` matches
every one of them**, and it is the catch-all that belongs last in a list, after the specific errors
you want to treat differently.

## Retry, then Catch

This machine sends to a queue that does not exist, so every attempt fails. Save it as
`~/aws/retry.asl.json`:

```schooling-example
{"language": "json", "file": "retry.asl.json", "parts": [{"code": "{\n  \"StartAt\": \"Notify\",\n  \"States\": {\n    \"Notify\": {\n      \"Type\": \"Task\",\n      \"Resource\": \"arn:aws:states:::sqs:sendMessage\",\n      \"Parameters\": {\n        \"QueueUrl\": \"https://sqs.sa-east-1.amazonaws.com/123456789012/missing\",\n        \"MessageBody\": \"42\"\n      },\n", "note": "The same task as before, pointed on purpose at a queue that does not exist, so that every attempt fails."}, {"code": "      \"Retry\": [\n        {\"ErrorEquals\": [\"States.ALL\"], \"IntervalSeconds\": 1, \"MaxAttempts\": 2, \"BackoffRate\": 2}\n      ],\n", "note": "`Retry` tries the task again: after 1 second, then after 1 × 2 = 2 seconds, and then gives up, because `MaxAttempts` counts the retries and not the first try."}, {"code": "      \"Catch\": [\n        {\"ErrorEquals\": [\"States.ALL\"], \"ResultPath\": \"$.error\", \"Next\": \"Failed\"}\n      ],\n      \"End\": true\n    },\n", "note": "`Catch` is what happens after the last retry: the error goes into `$.error` and the execution moves to `Failed` instead of stopping at the task."}, {"code": "    \"Failed\": {\"Type\": \"Fail\", \"Error\": \"NotifyFailed\", \"Cause\": \"the queue did not take the message\"}\n  }\n}\n", "note": "A `Fail` ends the execution with an error of your own naming, which is what an alarm or a caller reads."}]}
```

```
ana@laptop:~/aws$ RETRY=$(aws stepfunctions create-state-machine --name retry --definition file://retry.asl.json --role-arn "$ROLE" --query stateMachineArn --output text)
ana@laptop:~/aws$ aws stepfunctions start-execution --state-machine-arn "$RETRY" --name order-45 --input '{"id": "45"}' --query executionArn --output text
arn:aws:states:sa-east-1:123456789012:execution:retry:order-45
ana@laptop:~/aws$ sleep 5
ana@laptop:~/aws$ aws stepfunctions describe-execution --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "{status: status, error: error, cause: cause}"
{
    "status": "FAILED",
    "error": "NotifyFailed",
    "cause": "the queue did not take the message"
}
```

The execution failed with the error the `Fail` state names, not with SQS's. That is the point of
the `Catch`: whoever watches this workflow sees `NotifyFailed`, a name the team chose, and a cause
written for people. The history shows the rest:

```
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "events[].[id, type, timestamp]" --output text
1	ExecutionStarted	2026-10-16T13:31:56.235000-03:00
2	TaskStateEntered	2026-10-16T13:31:56.237000-03:00
3	TaskScheduled	2026-10-16T13:31:56.237000-03:00
4	TaskStarted	2026-10-16T13:31:56.237000-03:00
5	TaskFailed	2026-10-16T13:31:56.281000-03:00
6	TaskScheduled	2026-10-16T13:31:57.283000-03:00
7	TaskStarted	2026-10-16T13:31:57.283000-03:00
8	TaskFailed	2026-10-16T13:31:57.294000-03:00
9	TaskScheduled	2026-10-16T13:31:59.295000-03:00
10	TaskStarted	2026-10-16T13:31:59.295000-03:00
11	TaskFailed	2026-10-16T13:31:59.307000-03:00
12	TaskStateExited	2026-10-16T13:31:59.308000-03:00
13	FailStateEntered	2026-10-16T13:31:59.308000-03:00
14	ExecutionFailed	2026-10-16T13:31:59.308000-03:00
```

**Three attempts, and the gaps between them are the backoff.** The first try failed at 56.281; the
second was scheduled at 57.283, one second later, and the third at 59.295, two seconds after the
second failure, because `BackoffRate` doubled the interval. These are real seconds of this laptop,
because moto runs the waits. On AWS the same document gives the same schedule, and two settings
not used here change it: `MaxDelaySeconds` caps how long the gap may grow, and `JitterStrategy`
set to `FULL` randomises each gap, so that a thousand executions failing together do not all
retry in the same second.

The task's own error is in the failed events:

```
ana@laptop:~/aws$ aws stepfunctions get-execution-history --execution-arn "${RETRY/stateMachine/execution}:order-45" --query "events[?type==\`TaskFailed\`].taskFailedEventDetails | [0]"
{
    "resourceType": "sqs",
    "resource": "sendMessage",
    "error": "SQS.SdkClientException",
    "cause": "The specified queue does not exist."
}
```

`SQS.SdkClientException` is the name moto gives this failure. AWS names errors from its service
integrations after the service and the exception, so expect a different name there, and **match
real error names only after seeing them in a real history**; until then, `States.ALL` is the
honest choice.

## A retry runs the task again

Retrying is safe only for a task whose second run does no harm. **A task that runs twice is not a
rare event**: the first attempt can succeed at the far end and time out on the way back, and the
retry then does the same work again. For a message to a queue that means a duplicate, which a
consumer can be written to tolerate, and lesson 21 does exactly that. For a payment it means
charging a customer twice.

The defence is an **idempotency key**: an identifier that is the same on every attempt of the same
piece of work, which the service at the far end uses to recognise a repeat. The execution's name
is a natural one, because it is unique and it does not change between retries. `$$.Execution.Name`
reads it inside the document, and a task passes it on, for instance as the payment provider's
idempotency header or as the key of a conditional write in DynamoDB. A Standard workflow already
guarantees that the execution itself does not run twice; the key covers the retries you asked for,
and an Express workflow needs it everywhere.

## What not to retry

Some errors will fail again whatever happens. A `States.Permissions` error stays a permissions
error, and a validation error from the far end stays one. **Retry the transient and catch the
permanent**: name the errors that come and go (throttling, timeouts, a service briefly
unavailable) in the `Retry`, and let everything else reach the `Catch` at once rather than three
attempts later. A `Retry` on `States.ALL` with a high `MaxAttempts` turns every bug into a long
wait before the same failure.
