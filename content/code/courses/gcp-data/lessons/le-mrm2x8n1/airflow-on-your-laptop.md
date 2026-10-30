---
title: No emulator for Composer, and a real Airflow instead
version: 1
---

**Nothing imitates Cloud Composer.** Google publishes no emulator for it, fake-gcs-server knows
nothing about environments, and an environment is a Kubernetes cluster and a Cloud SQL instance
that no laptop could pretend to be. But **what Composer runs is Apache Airflow, and Apache Airflow
installs with pip**, with a SQLite file as its metadata database. So this section installs the same
Airflow on your machine and runs Quitanda's DAG with it, for real. What you get is the engine, not
the service: no environment, no bucket synchronised to a scheduler, no Google bill, and every
command that would create those is shown at the end and was not run.

## Airflow, in a virtual environment of its own

**Airflow pins hundreds of packages, and it gets a virtual environment of its own** so that none of
them moves a version the course's environment depends on. The Airflow project publishes a
*constraints file* per release and per Python version, the exact versions it was tested with, and
installing against it is how the project says to install:

```sh
python3 -m venv ~/gcp/airflow-venv
curl -sSLO https://raw.githubusercontent.com/apache/airflow/constraints-3.3.2/constraints-3.12.txt
~/gcp/airflow-venv/bin/pip install -q apache-airflow==3.3.2 --constraint constraints-3.12.txt
```

Then three lines for every terminal in which you use it. **The first puts `airflow` at the end of
the path**, after the course's environment, so that `python3` and `spark-submit` in a task are still
lesson 23's. The second says where Airflow keeps its files, turns off the example DAGs it would
otherwise load, and silences a warning about graphviz, a drawing library nothing here uses. The third moves Airflow's API server to port 8090, because its default, 8080, is the
port the Firestore emulator of lesson 10 uses:

```sh
export PATH="$PATH:$HOME/gcp/airflow-venv/bin"
export AIRFLOW_HOME=$HOME/gcp/airflow AIRFLOW__CORE__LOAD_EXAMPLES=False PYTHONWARNINGS=ignore::UserWarning
export AIRFLOW__API__PORT=8090 AIRFLOW__CORE__EXECUTION_API_SERVER_URL=http://localhost:8090/execution/
```

```
ana@laptop:~/gcp$ python3 -m venv ~/gcp/airflow-venv
ana@laptop:~/gcp$ ~/gcp/airflow-venv/bin/pip install -q apache-airflow==3.3.2 --constraint constraints-3.12.txt
ana@laptop:~/gcp$ airflow version
3.3.2
```

**Every Airflow setting is a line of `airflow.cfg` and an environment variable at once**:
`AIRFLOW__CORE__LOAD_EXAMPLES` is the `load_examples` option of the `[core]` section, two
underscores on each side of the section's name. Composer works the same way, and its environment
has a list of these overrides instead of a file you edit.

## The metadata database and the DAG folder

`airflow db migrate` creates the metadata database, a SQLite file in `$AIRFLOW_HOME`, and the DAG
folder is a directory under it. Save the DAG of the previous section in it:

```
ana@laptop:~/gcp$ airflow db migrate 2>&1 | tail -1
2026-10-30T18:59:10.700653Z [info     ] Database migration done!       [airflow.cli.commands.db_command] loc=db_command.py:152
ana@laptop:~/gcp$ mkdir -p $AIRFLOW_HOME/dags && cp quitanda_nightly.py $AIRFLOW_HOME/dags/
ana@laptop:~/gcp$ airflow dags reserialize > /dev/null 2>&1; airflow dags list -o plain 2>/dev/null | awk '{print $1, $4}'
dag_id is_paused
quitanda_nightly True
```

**`is_paused` is `True`, and that is Airflow being careful.** A new DAG starts paused, so a file
dropped into the folder by mistake schedules nothing until somebody unpauses it. Composer keeps the
same default.

## Render a task, then run the whole DAG

**Before running anything, ask Airflow what a task would do.** `airflow tasks render` fills in the
templates of one task for a given logical date and prints the result, without running it. The
logical date here is 06:00 UTC on the 30th, which is three in the morning in São Paulo, the moment
the schedule fires:

```
ana@laptop:~/gcp$ airflow tasks render quitanda_nightly export_orders 2026-10-30T06:00:00+00:00 2>/dev/null | grep -A2 'property: bash_command'
# property: bash_command
# ----------------------------------------------------------
python3 make_orders.py 2026-10-29
```

**`{DAY}` became 2026-10-29**: the run of the 30th processes the 29th, which is the day that has
finished. Then run the DAG once, all four tasks in order, with `airflow dags test`, which runs every
task in the terminal's own process without a scheduler, and records the run in the metadata
database like any other. Airflow writes a great deal while it does, so it goes to a file:

```
ana@laptop:~/gcp$ airflow dags test quitanda_nightly 2026-10-30T06:00:00+00:00 > test.log 2>&1; echo "exit $?"
exit 0
ana@laptop:~/gcp$ grep -o 'Running command: .*' test.log | cut -c1-110
Running command: ['/usr/bin/bash', '-c', 'python3 make_orders.py 2026-10-29'] [airflow.task.hooks.airflow.prov
Running command: ['/usr/bin/bash', '-c', "spark-submit --master 'local[2]' daily_orders.py --dt 2026-10-29 2> 
Running command: ['/usr/bin/bash', '-c', 'python3 check_daily.py 2026-10-29'] [airflow.task.hooks.airflow.prov
Running command: ['/usr/bin/bash', '-c', 'gcloud storage cp curated/daily_orders/dt=2026-10-29/* gs://quitanda
ana@laptop:~/gcp$ grep -oE '([0-9]+ orders read|│ +[0-9]).*' test.log | sed 's/ *\[airflow.*//'
20000 orders read, 500 customers written
│  20000 │   412139132 │
│       500 │  20000 │   412139132 │
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/daily_orders/
gs://quitanda-curated-prod/daily_orders/dt=2026-10-29/
ana@laptop:~/gcp$ airflow dags list-runs quitanda_nightly -o plain 2>/dev/null | cut -c1-120
dag_id            run_id                                    state    run_after                         logical_date     
quitanda_nightly  manual__2026-10-30T18:59:22.101271+00:00  success  2026-10-30T18:59:22.101271+00:00  2026-10-30T06:00:
```

**Four commands ran, in the order of the arrows**, each with the 29th filled in, and the check
printed the same counts and totals lesson 23 did. The last two commands show the result of the
last task, the day's Parquet in the curated bucket of the emulator, and the run Airflow kept a
record of: one run, `manual` because `dags test` started it rather than the schedule.

**This is the part of Composer the lab can show you, and it is most of what you write.** A DAG
file, its templates, its order and its retries behave the same on your laptop and in an
environment, because both are the same Airflow. What differs is what keeps running: here nothing
does once the command ends, and the next section is about what it costs to keep it running.

## What this lab cannot show you

**Everything that is Composer's own was not run here.** Creating an environment, which takes long
enough that people go and do something else; the scheduler picking a new file up from the
environment's bucket; a worker on Google's cluster running the tasks; the web interface; the logs
in Cloud Logging. The commands, **not run here**:

```sh
gcloud composer environments create quitanda \
  --location=southamerica-east1 --environment-size=small
gcloud composer environments storage dags import \
  --environment=quitanda --location=southamerica-east1 --source=quitanda_nightly.py
```

**`--environment-size` is the infrastructure's size, not the workers'**: it decides how much of the
database, the queue and the other managed parts the environment has, and the workers scale on their
own between limits you set. Leaving out `--image-version` gives Composer's default image, which
names a Composer version and an Airflow version together, and the DAG above, written against
`airflow.sdk`, needs an Airflow 3 image. Which images Google offers in São Paulo on a given day is on
its version list in the documentation, which this lab could not read. The second command is a copy
into the `dags/` folder of the environment's bucket, and the scheduler notices the file on its next
pass over the folder.
