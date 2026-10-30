---
title: What an environment costs while it waits
version: 1
---

**A Composer environment is billed for every hour it exists, and there is no way to pause one.**
It has no stopped state: the scheduler, the DAG processor, the web server, the database and at least
one worker run around the clock, because the scheduler has to be awake to notice that three in the
morning has arrived. The only way to stop paying is to delete the environment, which deletes its database and with it
the history of every run. Composer can save a *snapshot* to Cloud Storage
first and create a new environment from it later, which is a restore, not a pause. So the honest
question about Composer is not what a pipeline costs when it runs, but what the environment costs
when nothing does.

## Two generations, two ways of billing

Composer's pricing page, read on 2026-10-30, prices two current generations, and in São Paulo:

| generation | what is billed | price |
|---|---|---|
| Composer 3 | DCU-hours, everything the environment runs | $0.0954 per DCU-hour |
| Composer 3 | the Airflow database's storage | $0.000370274 per GiB-hour |
| Composer 2 | small environment fee | $0.56 an hour |
| Composer 2 | vCPU, memory and storage of the Airflow components | $0.072 per vCPU-hour, $0.008 per GiB-hour, $0.0003 per GiB-hour |
| Composer 2 | the Airflow database's storage | $0.000369863 per GiB-hour |

**Composer 3 folds everything into one unit**, the DCU, a Data Compute Unit that stands for the
processors, memory and storage of the environment's parts and of the managed infrastructure under
them. An environment is charged for its DCU value over time, and its workers' share moves with
autoscaling. **What the page does not say is how many DCUs a small Composer 3 environment uses when
it is doing nothing**; its one worked example uses 12 DCUs for five days, and the program below
takes that example as the figure, labelled as such. **Composer 2 is itemised**, and its page lists
exactly what the small preset starts with, which lets an idle month be computed rather than
borrowed: a scheduler, a web server and one worker at 0.5 vCPU, 1.875 GiB of memory and 1 GiB of
disk each, plus the fee. Both generations bill a database of at least 10 GiB.

## What grows with the work, and what does not

**The part of an environment that follows the work is its workers**, and only between limits you
set. A Composer environment scales its workers between a minimum and a maximum from the number of
tasks waiting, and the minimum is never zero, because something has to be ready to run the first
task of the night. The limits, the size of each worker and the packages the tasks import are
settings of the environment, changed with one command. **Not run here:**

```sh
gcloud composer environments update quitanda --location=southamerica-east1 \
  --min-workers=1 --max-workers=3
gcloud composer environments update quitanda --location=southamerica-east1 \
  --update-pypi-package=holidays==0.105
```

**The second command is a reason to plan the first.** Installing a package rebuilds the
environment's image and restarts its components, which takes long enough that a team does it in a
quiet hour, not in the middle of a night's runs. And neither command changes the part of the bill
that does not move: the scheduler, the DAG processor, the web server, the database and the minimum
worker are there at four in the afternoon as at three in the morning, which is what the program
below prices.

## A month, doing almost nothing

Quitanda's pipeline is lesson 23's job and its three neighbours, about an hour a night. Save the
bill as `composer_bill.py`:

```schooling-example
{"language": "python", "file": "composer_bill.py", "parts": [{"code": "# USD, southamerica-east1, read on 2026-10-30, from cloud.google.com/composer/pricing.\nC3_DCU = 0.0954            # Composer 3, a DCU-hour (the page: $0.0954 per 1,000 milli DCU-hours)\nC3_DB = 0.000370274        # Composer 3, database storage, a GiB-hour\nC2_SMALL = 0.56            # Composer 2, small environment fee, an hour\nC2_VCPU = 0.072            # Composer 2, a vCPU-hour (the page: $0.072 per 1,000 mCPU-hours)\nC2_GIB = 0.008             # Composer 2, a GiB-hour of memory\nC2_DISK = 0.0003           # Composer 2, a GiB-hour of storage\nC2_DB = 0.000369863        # Composer 2, database storage, a GiB-hour\nDB_GIB, HOURS = 10, 730    # the smallest database the page allows, and an average month\n\n", "note": "Seven prices from one page, two generations of the same product. The units are the page's own, converted in the comments: a thousand milli DCU-hours is one DCU-hour, and a thousand mCPU-hours is one vCPU-hour."}, {"code": "c3 = (12 * C3_DCU + DB_GIB * C3_DB) * HOURS\nc2 = (C2_SMALL + 1.5 * C2_VCPU + 5.625 * C2_GIB + 3 * C2_DISK + DB_GIB * C2_DB) * HOURS\nfor name, usd in [('Composer 3, 12 DCUs', c3), ('Composer 2, small, idle', c2)]:\n    print(f'{name:<25}{usd:8.2f} a month {usd * 12:9.2f} a year')\n\n", "note": "**Two environments that run all month whatever they do.** Composer 3 at the 12 DCUs of the page's own example. Composer 2 in the small preset with one worker, which the page lists as a scheduler, a web server and a worker at 0.5 vCPU, 1.875 GiB and 1 GiB of disk each."}, {"code": "WORK = 30                  # Quitanda's pipeline: about an hour a night, thirty nights\nprint(f'per hour of work: {c3 / WORK:.2f} and {c2 / WORK:.2f}')\n\n", "note": "The same two months divided by the hours the pipeline works in them."}, {"code": "# cloud.google.com/workflows/pricing and cloud.google.com/scheduler/pricing, read 2026-10-30\nSTEPS, FREE_STEPS, PER_1000 = 100 * 30, 5000, 0.01    # a generous 100 steps a run\nJOBS, FREE_JOBS, PER_JOB = 1, 3, 0.10\nworkflows = max(0, -(-(STEPS - FREE_STEPS) // 1000)) * PER_1000\nscheduler = max(0, JOBS - FREE_JOBS) * PER_JOB\nprint(f'Workflows, {STEPS} steps: {workflows:.2f}  Cloud Scheduler, {JOBS} job: {scheduler:.2f}')\n", "note": "**The lighter pair, for the same pipeline.** Workflows bills internal steps in increments of a thousand beyond 5,000 free a month, and Cloud Scheduler $0.10 a job beyond three free per billing account. A hundred steps a night is generous for four steps and the polling of a batch."}]}
```

```
ana@laptop:~/gcp$ python3 composer_bill.py
Composer 3, 12 DCUs        838.41 a month  10060.88 a year
Composer 2, small, idle    523.85 a month   6286.16 a year
per hour of work: 27.95 and 17.46
Workflows, 3000 steps: 0.00  Cloud Scheduler, 1 job: 0.00
```

**523.85 a month for the smallest Composer 2 environment, and 838.41 for Composer 3 at the page's
example.** Both lines are what the environment costs with no DAG running at all, because nothing in
them depends on the work. Divided by the thirty hours a month the pipeline actually works, the
orchestration costs 17.46 and 27.95 per hour of work, before a single DCU of Dataproc, which is
billed on its own. The environment's bucket, its operations and its logs in Cloud Logging are billed
on their own pages too, and are left out.

**The last line is the other answer, and it is zero.** A hundred workflow steps a night is 3,000
steps a month, inside the 5,000 Workflows gives free; one Cloud Scheduler job is inside the three
free per billing account. Free is a property of this one pipeline, not of the products: a platform
with forty workflows of a hundred steps a night runs 120,000 steps a month, which beyond the free
5,000 is 115 increments of a thousand at $0.01, $1.15.

## The shape of the bill, against everything else in this course

**Composer charges for waiting and almost nothing more for working**, which is the opposite of
Dataflow, Dataproc Serverless and BigQuery on demand, which charge for work and nothing for
waiting. That makes it cheap per pipeline when there are many pipelines and expensive per pipeline
when there are few. Forty DAGs sharing one small Composer 2 environment cost 523.85 ÷ 40 = 13.10 a
month each, and nobody would call that dear for a scheduler with retries, backfills, sensors and a
web interface. One DAG on its own pays the whole 523.85.

## When the waiting is worth it

**Composer earns its price when Airflow itself is the point.** Many DAGs, written by several teams,
with dependencies between them; backfills, where re-running last Tuesday is one command; sensors
that wait for a file or a table to appear; operators for dozens of services beyond Google's; and a
team that already knows Airflow, or a pipeline that may have to move to another cloud one day,
where Airflow runs too. For that, five to eight hundred dollars a month is a reasonable price for
not operating a scheduler, a database and a fleet of workers yourself.

**It does not earn it for a handful of simple pipelines**, each a short chain of calls run on a
clock. That case has a cheaper answer made of two services that cost nothing while they wait, and
the next section builds it.
