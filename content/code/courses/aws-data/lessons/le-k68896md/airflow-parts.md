---
title: Airflow's parts, and what MWAA runs for you
version: 1
---

**Airflow is not a job runner; it is a scheduler of other people's jobs.** A pipeline in Airflow is
a **DAG**, a directed acyclic graph of tasks written as a Python file. A task is usually a call to
something else: start a Glue job, run a query in Athena, submit a step to EMR, wait for a file to
land in S3. Airflow decides when each task may start, starts it, watches it, retries it when it
fails, and remembers what happened. The heavy work happens in the services it calls, which is why a
small Airflow can orchestrate a large data platform.

Five parts make an Airflow, and all five have to be running for any of it to work:

- the **scheduler** reads the DAG files, works out which tasks are due and hands them to the
  workers. It is the part that has to be up at three in the morning;
- the **workers** run the tasks. Under the Celery executor, which MWAA uses, they are separate
  machines taking tasks from a queue, and their number can grow and shrink;
- the **web server** is the interface where people look at runs, read logs and clear a failed task
  to run it again;
- the **metadata database** holds the state of every DAG run and task instance, and it is what the
  scheduler reads to decide what is due. Lose it and Airflow forgets its history;
- the **DAG folder** is where the Python files live, and every part reads it.

**MWAA is all five, run by AWS, with the DAG folder in S3.** You create an *environment*, give it a
bucket, two private subnets of your VPC and a role, and AWS runs the scheduler, the web server, the
workers and the database in its own account, out of your sight. You never see the machines or the
database. What you see is the bucket, where you put DAGs, a `requirements.txt` naming the Python
packages the tasks need, and the logs it writes to CloudWatch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two dashed boundaries. On the left, an MWAA environment in AWS's account holds four parts: the scheduler, which decides what is due; the web server, for runs, logs and retries; the workers, one base and two extras that come and go with the load, which run the tasks; and the metadata database, which records every DAG run and task instance. On the right, your account holds the bucket s3://quitanda-airflow-prod with dags/nightly_orders.py and requirements.txt, versioned and not public, and the services where the work runs, Glue, EMR and Athena, billed on their own. An arrow goes from the bucket to the scheduler, and another from the workers to Glue, EMR and Athena.\" data-fig=\"l25-parts\"><defs><marker id=\"ah-l25-parts\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an MWAA environment, in AWS's account</text><rect x=\"230\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">scheduler</text><text x=\"315\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decides what is due</text><rect x=\"40\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">web server</text><text x=\"125\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runs, logs, retries</text><rect x=\"230\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">workers</text><rect x=\"245\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"295\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"345\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">base</text><text x=\"315\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"365\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"315\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run the tasks; extras</text><text x=\"315\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">come and go with the load</text><rect x=\"40\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">metadata database</text><text x=\"125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every DAG run and</text><text x=\"125\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">task instance</text><rect x=\"450\" y=\"20\" width=\"255\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">your account</text><rect x=\"465\" y=\"60\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">s3://quitanda-airflow-prod</text><text x=\"577\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dags/nightly_orders.py</text><text x=\"577\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">requirements.txt</text><text x=\"577\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">versioned, not public</text><rect x=\"465\" y=\"170\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Glue, EMR, Athena</text><text x=\"577\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">where the work runs,</text><text x=\"577\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">billed on its own</text><line x1=\"463\" y1=\"88\" x2=\"402\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l25-parts)\"></line><line x1=\"402\" y1=\"215\" x2=\"463\" y2=\"215\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l25-parts)\"></line></svg>", "caption": "MWAA runs the five parts of Airflow out of sight; you keep the DAG folder, and the work happens in the services the tasks call."}
```

## A DAG, as Quitanda would write it

Quitanda's nightly pipeline is two Glue jobs: load the day's orders, then build the daily table from
them. As an Airflow DAG it is the file below. **It is not run in this lab**, which has no Airflow and,
as the next section shows, no MWAA either; it is shown because the file is what a team writes, and the
section after that writes the same pipeline for Step Functions.

```schooling-example
{"language": "python", "file": "nightly_orders.py", "parts": [{"code": "from datetime import datetime, timedelta\n\nfrom airflow import DAG\nfrom airflow.providers.amazon.aws.operators.glue import GlueJobOperator\n\n", "note": "`GlueJobOperator` comes from Airflow's Amazon provider, the package of operators that call AWS services. MWAA environments come with it installed."}, {"code": "with DAG(\n    dag_id='quitanda_nightly',\n    schedule='0 3 * * *',\n    start_date=datetime(2026, 10, 1),\n    catchup=False,\n    default_args={'retries': 2, 'retry_delay': timedelta(minutes=5)},\n) as dag:\n", "note": "**The DAG itself.** A cron expression for three in the morning, the date the schedule starts from, and `catchup=False`, so that Airflow does not run every night since 1 October the moment the file appears. Every task inherits two retries, five minutes apart."}, {"code": "    load = GlueJobOperator(\n        task_id='load_orders',\n        job_name='load-orders',\n        script_args={'--dt': '{{ ds }}'},\n    )\n    daily = GlueJobOperator(\n        task_id='build_daily',\n        job_name='build-daily',\n        script_args={'--dt': '{{ ds }}'},\n    )\n", "note": "Two tasks, each starting a Glue job and waiting for it to finish. `{{ ds }}` is filled in by Airflow with the date of the interval the run covers: the run at three in the morning of the 16th covers the 15th, which is exactly the partition the job should read."}, {"code": "    load >> daily\n", "note": "The one dependency: `build_daily` starts when `load_orders` has succeeded, and not before."}]}
```

**`{{ ds }}` is the detail that shows what Airflow is for.** Airflow thinks in intervals: every run
covers a stretch of time, knows which one, and can be re-run for it. Clear the run of 12 October in
the web server and it runs again with `ds` set to `2026-10-12`; set `catchup=True` and a new DAG fills
every interval since its start date. That is called a **backfill**, and it is the feature teams miss
first when they leave Airflow, because nothing else in this lesson knows what "the run for the 12th"
means.

## The DAG folder is a bucket you can build here

The bucket is plain S3, and moto stores it faithfully. With moto running in its own terminal and the
four lines of lesson 1's "Your lab, in brief" typed in this one, save the DAG above as
`nightly_orders.py` and give it the bucket MWAA would read:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-airflow-prod
make_bucket: quitanda-airflow-prod
ana@laptop:~/aws$ aws s3api put-bucket-versioning --bucket quitanda-airflow-prod --versioning-configuration Status=Enabled
ana@laptop:~/aws$ aws s3 cp nightly_orders.py s3://quitanda-airflow-prod/dags/nightly_orders.py
upload: ./nightly_orders.py to s3://quitanda-airflow-prod/dags/nightly_orders.py
ana@laptop:~/aws$ aws s3api list-object-versions --bucket quitanda-airflow-prod --query "Versions[].[Key,IsLatest]" --output text
dags/nightly_orders.py	True
```

**MWAA refuses a bucket without versioning**, which is why the second command turns it on: the
environment records which version of each file it loaded, and a bucket that cannot answer that
question cannot be its DAG folder. It also asks for Block Public Access on the bucket, the setting lesson 4 is about. On AWS the
scheduler would pick the new file up on its next pass over the folder and draw the DAG in the web
server; here the file is in the bucket and nothing reads it.
