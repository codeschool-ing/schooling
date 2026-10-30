---
title: The same pipeline as a workflow, started by Cloud Scheduler
version: 1
---

**Workflows runs a pipeline written as a list of steps**, in YAML: each step assigns a variable,
makes a call or decides where to go next, and a call to a Google API through a **connector** waits
for a long-running operation to finish before the next step starts. Nothing runs between executions
and nothing is billed between them: Workflows charges per step executed, and **Cloud Scheduler**,
which starts things on a clock, charges per job defined. Neither has an emulator, so this section is
read, and every command in it is marked as not run.

Here is Quitanda's pipeline as a workflow, with the Spark job as a Dataproc Serverless batch. Save it
as `nightly.yaml`:

`nightly.yaml`:

```yaml
main:
  steps:
    - pick_day:
        assign:
          - day: ${text.substring(time.format(sys.now() - 86400, "America/Sao_Paulo"), 0, 10)}
    - daily_orders:
        call: googleapis.dataproc.v1.projects.locations.batches.create
        args:
          parent: projects/planner-dev/locations/southamerica-east1
          batchId: ${"daily-orders-" + day}
          body:
            pysparkBatch:
              mainPythonFileUri: gs://quitanda-raw-prod/jobs/daily_orders.py
              args: ["--dt", "${day}", "--src", "gs://quitanda-raw-prod/raw",
                     "--dst", "gs://quitanda-curated-prod"]
        result: batch
    - done:
        return: ${batch.state}
```

**Read it against the DAG and the two line up, with one difference.** `daily_orders` is the
`DataprocCreateBatchOperator` of the first section, and the connector submits the batch and waits
for it the way the operator did. A step can be wrapped in a `try` with a `retry` policy, which is
how a workflow gets the DAG's two retries; this one is left without, to stay short.

**What has no counterpart is the interval.** Airflow knew which day a run was for; a workflow knows
only when it is running, so `pick_day` works out "yesterday" from the clock, `sys.now()` less a
day's seconds, formatted in São Paulo's time. Run late, it still computes the day before the moment it runs, which is right. Re-run on the 3rd for the 1st, it computes the 2nd, which is wrong, and the
only way to re-run a past night is to pass the day in as an argument, which this workflow does not
take. There is no backfill either: re-running a week means starting seven executions by hand. For a
pipeline that runs every night and is rarely re-run, that is a fair trade; for one that is re-run
often, it is the first thing that hurts.

Deploying it is one command, **not run here**:

```sh
gcloud workflows deploy quitanda-nightly --location=southamerica-east1 \
  --source=nightly.yaml --service-account=quitanda-pipeline@planner-dev.iam.gserviceaccount.com
```

The service account is the identity the workflow acts as, and it needs the right to create Dataproc
batches and nothing else. `gcp-foundations` is where service accounts and their roles are made.

## Three in the morning, by Cloud Scheduler

**Cloud Scheduler starts things on a clock**: a job names a schedule and a target, and at that time
it calls the target. Here the target is the Workflows API's endpoint for starting an execution. One
thing about it is worth asking the command line before writing the job, because it decides which
three in the morning it is:

```
ana@laptop:~/gcp$ gcloud scheduler jobs create http --help | grep -A1 -E -- '^ +--time-zone'
     --time-zone=TIME_ZONE; default="Etc/UTC"
        Specifies the time zone to be used in interpreting --schedule. The
```

**The default time zone is `Etc/UTC`.** A job created with `--schedule='0 3 * * *'` and no
`--time-zone` fires at three in the morning UTC, which is midnight in São Paulo, and the workflow
would then compute "yesterday" three hours before the day had ended. So the job says its zone. **Not
run here:**

```sh
gcloud scheduler jobs create http quitanda-nightly --location=southamerica-east1 \
  --schedule='0 3 * * *' --time-zone=America/Sao_Paulo \
  --uri=https://workflowexecutions.googleapis.com/v1/projects/planner-dev/locations/southamerica-east1/workflows/quitanda-nightly/executions \
  --http-method=POST \
  --oauth-service-account-email=quitanda-scheduler@planner-dev.iam.gserviceaccount.com
```

**The cron expression has five fields**, minutes, hours, day of month, month and day of week, the
same Unix form the DAG's `schedule` used, so the two can be read against each other. The service
account is the one Scheduler uses to call Workflows, and it needs the right to start executions of
this one workflow. If the call fails, Scheduler retries it according to the job's retry settings,
and it does not know or care whether the workflow then succeeds: a failed batch shows up as a failed
execution in Workflows, and somebody has to be told about it by an alert, which neither service sends
on its own.

## What each of the two keeps

| | Composer | Workflows with Cloud Scheduler |
|---|---|---|
| pipeline written as | Python, in a DAG file | YAML, in a workflow |
| which day a run is for | the run's logical date and data interval | the clock, at the moment it runs |
| backfill | a command, for any range of days | an execution per day, started by hand |
| waiting for a file | a sensor | a loop of steps, or an Eventarc trigger that starts the workflow |
| history of runs | the metadata database and the web interface | each execution, its steps and its result |
| what you operate | the environment's size, its packages, its upgrades | the definitions |
| idle cost | the environment, every hour | nothing |

The previous section put a number on the last line; the next one is about the second and the third.
