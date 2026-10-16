---
title: Three in the morning, and which of the two to choose
version: 1
---

**EventBridge Scheduler starts things on a clock**: a schedule names a time, a target and the input
to give it, and at that time it calls the target. It replaces the job of the scheduler in Airflow,
and nothing else; the pipeline's order, retries and waiting belong to the state machine it starts.
It bills per invocation, and its line, like Step Functions', is not in this course's price sheet.

The schedule's target is the state machine, and its input carries the moment the schedule fired.
Save the target as `target.json`:

`target.json`:

```json
{
  "Arn": "arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly",
  "RoleArn": "arn:aws:iam::123456789012:role/quitanda-scheduler",
  "Input": "{\"scheduled\": \"<aws.scheduler.scheduled-time>\"}"
}
```

**`<aws.scheduler.scheduled-time>` is filled in by Scheduler when it fires**, with the time the run
was due rather than the time it happened to start, which is what the Glue job should compute
"yesterday" from. The role is the one Scheduler assumes to call Step Functions, and the input is a
JSON document written as a string inside JSON, which is why its quotes are escaped. Create the
schedule:

```
ana@laptop:~/aws$ aws scheduler create-schedule --name quitanda-nightly --schedule-expression 'cron(0 3 * * ? *)' --schedule-expression-timezone America/Sao_Paulo --flexible-time-window Mode=OFF --target file://target.json
{
    "ScheduleArn": "arn:aws:scheduler:sa-east-1:123456789012:schedule/default/quitanda-nightly"
}
ana@laptop:~/aws$ aws scheduler get-schedule --name quitanda-nightly
{
    "Arn": "arn:aws:scheduler:sa-east-1:123456789012:schedule/default/quitanda-nightly",
    "CreationDate": "2026-10-16T13:07:42.676690-03:00",
    "FlexibleTimeWindow": {
        "Mode": "OFF"
    },
    "GroupName": "default",
    "LastModificationDate": "2026-10-16T13:07:42.676690-03:00",
    "Name": "quitanda-nightly",
    "ScheduleExpression": "cron(0 3 * * ? *)",
    "ScheduleExpressionTimezone": "America/Sao_Paulo",
    "State": "ENABLED",
    "Target": {
        "Arn": "arn:aws:states:sa-east-1:123456789012:stateMachine:quitanda-nightly",
        "Input": "{\"scheduled\": \"<aws.scheduler.scheduled-time>\"}",
        "RetryPolicy": {
            "MaximumEventAgeInSeconds": 86400,
            "MaximumRetryAttempts": 185
        },
        "RoleArn": "arn:aws:iam::123456789012:role/quitanda-scheduler"
    }
}
```

**`cron(0 3 * * ? *)` has six fields, not five**, and that is AWS's cron, not Unix's: minutes,
hours, day of month, month, day of week and year, with a `?` in one of the two day fields to say
"whichever". With `--schedule-expression-timezone America/Sao_Paulo` the three is São Paulo's three,
which is six in the morning UTC; without it, the schedule would fire at midnight in São Paulo. The
retry policy was filled in by default, as AWS also does: up to 185 attempts within a day, for a target
that refuses to start.

**moto keeps the schedule and fires nothing.** At three in the morning nothing will happen in this
lab, because moto has no clock that calls targets. And it checks less than AWS: give it the
five-field cron of the DAG and it accepts that too.

```
ana@laptop:~/aws$ aws scheduler create-schedule --name quitanda-five-fields --schedule-expression 'cron(0 3 * * *)' --flexible-time-window Mode=OFF --target file://target.json
{
    "ScheduleArn": "arn:aws:scheduler:sa-east-1:123456789012:schedule/default/quitanda-five-fields"
}
ana@laptop:~/aws$ aws scheduler list-schedules --query 'Schedules[].[Name,State]' --output text
quitanda-five-fields	ENABLED
quitanda-nightly	ENABLED
```

**On AWS that call is refused** with a validation error, because `cron(0 3 * * *)` is not a valid
AWS cron expression; moto stored it as written. A schedule that is wrong in this way never fires, and
on a real account the error at creation is what saves you from a pipeline that silently never ran.

## MWAA, or Step Functions and Scheduler

**Choose by the number and the shape of the pipelines, not by the size of the data**, because neither
does the heavy work: both start Glue, EMR or Athena and wait.

| | MWAA | Step Functions with Scheduler |
|---|---|---|
| idle cost | 615.02 a month for the smallest environment of the sheet | nothing between runs |
| pipeline written as | Python, in a DAG file | JSON, in a state machine |
| intervals and backfill | built in: every run knows its interval | none: the input carries a timestamp |
| waiting for a file or a partition | sensors | a loop of states, or an event that starts the machine |
| services outside AWS | many operators | an HTTP call, or a Lambda written for it |
| what you operate | the environment's size, its packages, its upgrades | the definitions |

**For Quitanda today, with one pipeline of two steps, Step Functions with Scheduler is the answer**:
the same order, the same retries, and no 615.02 a month for a scheduler that waits. The day there are
thirty DAGs, three teams and a habit of re-running last week, the table turns, and moving to MWAA is
work the team will be glad of rather than a cost it resents. Writing the first pipeline so that
each step is its own Glue job, with its date as an argument, is what keeps that move cheap: the jobs
stay, and only the thing that starts them changes.
