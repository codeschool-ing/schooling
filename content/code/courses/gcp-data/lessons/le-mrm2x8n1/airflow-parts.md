---
title: Airflow's parts, and what Composer runs for you
version: 1
---

**Airflow is not a job runner; it is a scheduler of other people's jobs.** A pipeline in Airflow is
a **DAG**, a directed acyclic graph of tasks written as a Python file. A task is usually a call to
something else: submit a Spark batch to Dataproc, run a query in BigQuery, wait for an object to
land in a bucket. Airflow decides when each task may start, starts it, watches it, retries it when
it fails, and remembers what happened. The heavy work happens in the services it calls, which is
why a small Airflow can orchestrate a large data platform.

Five parts make an Airflow, and all of them have to be running for any of it to work:

- the **scheduler** works out which tasks are due and hands them to the workers. It is the part that
  has to be awake at three in the morning;
- the **DAG processor** reads the DAG files and turns each into the structure the scheduler plans
  from. Airflow 3 runs it as a process of its own, where Airflow 2 ran it inside the scheduler;
- the **workers** run the tasks. Under the Celery executor, which Composer uses, they are separate
  processes taking tasks from a queue, and their number can grow and shrink;
- the **web server**, which Airflow 3 calls the API server, is the interface where people look at
  runs, read logs and clear a failed task to run it again, and the endpoint a running task reports
  its state to;
- the **metadata database** holds the state of every DAG run and task instance, and it is what the
  scheduler reads to decide what is due. Lose it and Airflow forgets its history.

And there is the **DAG folder**, where the Python files live, which every part reads.

**Cloud Composer is all of them, run by Google, with the DAG folder in a bucket.** You create an
*environment* in a region, and Google runs the scheduler, the DAG processor, the triggerer, the web
server and the workers on a Kubernetes cluster, and the metadata database on Cloud SQL. In Composer
3, the current generation, both live in a project of Google's, out of your sight. What you see is a
Cloud Storage bucket the environment creates for itself, with a `dags/` folder for the DAG files, a
`data/` folder, and a `logs/` folder where every task's log lands, plus the list of Python packages
the tasks need, which you set on the environment. Google's pricing page, read on 2026-10-30, calls
the product *Managed Service for Apache Airflow*; the command line still says `gcloud composer`,
and so does this lesson.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two dashed boundaries. On the left, a Composer 3 environment in Google's project holds four parts: the scheduler, which decides what is due; the API server, for runs, logs and retries; the workers, a minimum and two extras that come and go with the load, which run the tasks; and the metadata database on Cloud SQL, which records every DAG run and task instance. On the right, your project holds the environment bucket, created with the environment, with dags/quitanda_nightly.py and logs/, and the services where the work runs, Dataproc and BigQuery, billed on their own. An arrow goes from the bucket to the scheduler, and another from the workers to Dataproc and BigQuery.\" data-fig=\"l24-parts\"><defs><marker id=\"ah-l24-parts\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a Composer 3 environment, in Google's project</text><rect x=\"230\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">scheduler</text><text x=\"315\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">decides what is due</text><rect x=\"40\" y=\"60\" width=\"170\" height=\"55\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">API server</text><text x=\"125\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">runs, logs, retries</text><rect x=\"230\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">workers</text><rect x=\"245\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"295\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"345\" y=\"172\" width=\"40\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">min</text><text x=\"315\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"365\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">extra</text><text x=\"315\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run the tasks; extras</text><text x=\"315\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">come and go with the load</text><rect x=\"40\" y=\"135\" width=\"170\" height=\"125\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">metadata database</text><text x=\"125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud SQL: every DAG</text><text x=\"125\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run and task instance</text><rect x=\"450\" y=\"20\" width=\"255\" height=\"260\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">your project</text><rect x=\"465\" y=\"60\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the environment bucket</text><text x=\"577\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dags/quitanda_nightly.py</text><text x=\"577\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">logs/</text><text x=\"577\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">created with the environment</text><rect x=\"465\" y=\"170\" width=\"225\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"577\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Dataproc, BigQuery</text><text x=\"577\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">where the work runs,</text><text x=\"577\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">billed on its own</text><line x1=\"463\" y1=\"88\" x2=\"402\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l24-parts)\"></line><line x1=\"402\" y1=\"215\" x2=\"463\" y2=\"215\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l24-parts)\"></line></svg>", "caption": "Composer runs Airflow's parts out of sight; you keep the bucket, and the work happens in the services the tasks call."}
```

## A DAG, as Quitanda would write it

Quitanda's nightly pipeline is lesson 23's work, in order: make the night's export of orders, run
the Spark job on it, check the result, and publish it to the curated bucket. As an Airflow DAG it is
the file below. **It runs on your laptop in the next section**, with every task a command lesson 23
already ran, so that the Airflow is real and nothing in it needs Google. Save it as
`quitanda_nightly.py`:

```schooling-example
{"language": "python", "file": "quitanda_nightly.py", "parts": [{"code": "from pathlib import Path\n\nimport pendulum\nfrom airflow.providers.standard.operators.bash import BashOperator\nfrom airflow.sdk import DAG\n\n", "note": "`DAG` comes from `airflow.sdk`, the module Airflow 3 writes DAGs against. `BashOperator` comes from the standard provider, which installs with Airflow itself."}, {"code": "DAY = '{{ macros.ds_add(ds, -1) }}'\n\n", "note": "**The day the run works on: the day before the one it runs.** `ds` is the date of the run's logical date, and on Airflow 3's default cron schedule that is the night the run happens, so the 3 a.m. run of the 30th has `ds` 2026-10-30 and must process the 29th. The section on scheduling shows it."}, {"code": "with DAG(\n    dag_id='quitanda_nightly',\n    schedule='0 3 * * *',\n    start_date=pendulum.datetime(2026, 10, 26, tz='America/Sao_Paulo'),\n    catchup=False,\n    default_args={'retries': 2, 'retry_delay': pendulum.duration(minutes=5),\n                  'cwd': str(Path.home() / 'gcp')},\n) as dag:\n", "note": "**The DAG itself.** A cron expression for three in the morning, in São Paulo's time because the start date carries that zone, and `catchup=False`, so that Airflow does not run every night since 26 October the moment the file appears. Every task inherits two retries five minutes apart, and runs in `~/gcp`."}, {"code": "    export = BashOperator(task_id='export_orders',\n                          bash_command=f'python3 make_orders.py {DAY}')\n    daily = BashOperator(task_id='daily_orders',\n                         bash_command=f\"spark-submit --master 'local[2]' daily_orders.py --dt {DAY} 2> spark.log\")\n    check = BashOperator(task_id='check',\n                         bash_command=f'python3 check_daily.py {DAY}')\n    publish = BashOperator(task_id='publish',\n                           bash_command=f'gcloud storage cp curated/daily_orders/dt={DAY}/* '\n                                        f'gs://quitanda-curated-prod/daily_orders/dt={DAY}/')\n", "note": "Four tasks, each a command from lesson 23: make the day's export, run the Spark job on it, check the result with DuckDB, and copy it to the curated bucket. Airflow fills in `{DAY}` when the task runs, because it is a template."}, {"code": "    export >> daily >> check >> publish\n", "note": "The dependencies: each task starts when the one before it has succeeded, and not before. A failed check stops the publish, which is the point of having one."}]}
```

**Read the file as a description, not as a program that does the work.** Running it creates four operators and three arrows and nothing else. The scheduler reads that description from the DAG
folder, and at three in the morning creates a *DAG run* for the night and *task instances* for its
four tasks, each of which a worker runs when the arrows allow. The `{DAY}` in each command is
rendered for that run alone, which is what lets the same file run every night, and re-run any
night of the past, with the right date.

## The same DAG, on Composer

On Composer, the tasks would not be shell commands on a laptop. **The export is an object that
lands in a bucket, and the Spark job is a Dataproc Serverless batch**, and Airflow's Google provider
has an operator or a sensor for each. The two tasks that would change, **not run here**, because
the provider is a large package and has no Google to call:

```python
from airflow.providers.google.cloud.operators.dataproc import DataprocCreateBatchOperator
from airflow.providers.google.cloud.sensors.gcs import GCSObjectExistenceSensor

export = GCSObjectExistenceSensor(
    task_id='export_orders',
    bucket='quitanda-raw-prod',
    object=f'raw/orders/dt={DAY}/orders.csv',
)
daily = DataprocCreateBatchOperator(
    task_id='daily_orders',
    project_id='planner-dev',
    region='southamerica-east1',
    batch_id=f'daily-orders-{DAY}',
    batch={'pyspark_batch': {
        'main_python_file_uri': 'gs://quitanda-raw-prod/jobs/daily_orders.py',
        'args': ['--dt', DAY, '--src', 'gs://quitanda-raw-prod/raw',
                 '--dst', 'gs://quitanda-curated-prod'],
    }},
)
```

**The sensor waits; the operator submits and waits.** `GCSObjectExistenceSensor` checks for the
night's file until it appears, so the pipeline starts when the shop's export has landed rather than
at a time somebody hoped it would have. `DataprocCreateBatchOperator` submits lesson 23's batch and
waits for it to end, failing the task if the batch fails. The arrows, the retries and the `{DAY}`
are the same as in the file above, and that is the point of writing the pipeline this way: the
graph and its dates are Airflow's, and the work is somebody else's.
