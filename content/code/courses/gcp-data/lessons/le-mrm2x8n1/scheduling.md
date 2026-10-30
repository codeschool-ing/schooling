---
title: Which night a run is for, catching up, and which of the two to choose
version: 1
---

**A scheduled run in Airflow knows which date it is for, and that date is not the moment it
starts.** Every run has a **logical date**, from which `ds` and the other template values are made,
and on most schedules a **data interval**, the stretch of time the run is meant to process. A
pipeline that reads "yesterday's orders" is only right if it computes yesterday from those, and not
from the clock, so that a run started late, or re-run a week later, still processes the night it was
for. Which date a run is given depends on the schedule's *timetable*, and Airflow 3 changed the
default.

## Two timetables for the same cron expression

**`schedule='0 3 * * *'` in Airflow 3 means `CronTriggerTimetable`**: a run fires at each 03:00,
and its logical date is that moment, so its interval has no length. Airflow 2 read the same string as
`CronDataIntervalTimetable`: each run covers the day from one 03:00 to the next and fires when that
day has ended, with the start of the interval as its logical date. The DAG file below declares one
DAG of each, with `catchup=True`, and a task that prints what the run was given. Save it in the DAG
folder as `two_clocks.py`:

`two_clocks.py`:

```python
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG
from airflow.timetables.interval import CronDataIntervalTimetable

SAY = 'echo {{ dag.dag_id }} ds={{ ds }} start={{ data_interval_start }} end={{ data_interval_end }}'
START = pendulum.datetime(2026, 10, 26, tz='America/Sao_Paulo')

with DAG('clock_trigger', schedule='0 3 * * *', start_date=START, catchup=True):
    BashOperator(task_id='say', bash_command=SAY)

with DAG('clock_interval', start_date=START, catchup=True,
         schedule=CronDataIntervalTimetable('0 3 * * *', timezone='America/Sao_Paulo')):
    BashOperator(task_id='say', bash_command=SAY)
```

**Running a schedule takes the two long-lived parts of Airflow**: the API server, which tasks report
to, and the scheduler, which creates the runs. Each runs in the foreground in a terminal of its own,
with the three exports from earlier in this lesson typed there too:

```sh
airflow api-server
```

```sh
airflow scheduler
```

Unpause both DAGs, give the scheduler a minute, and ask what it did. The capture below was made on
30 October, in the evening:

```
ana@laptop:~/gcp$ airflow dags reserialize > /dev/null 2>&1; airflow dags unpause clock_trigger > /dev/null 2>&1; airflow dags unpause clock_interval > /dev/null 2>&1
ana@laptop:~/gcp$ airflow dags list-runs clock_trigger -o plain 2>/dev/null | awk '{print $3, $4}'
state run_after
success 2026-10-30T06:00:00+00:00
success 2026-10-29T06:00:00+00:00
success 2026-10-28T06:00:00+00:00
success 2026-10-27T06:00:00+00:00
success 2026-10-26T06:00:00+00:00
ana@laptop:~/gcp$ airflow dags list-runs clock_interval -o plain 2>/dev/null | awk '{print $3, $4}'
state run_after
success 2026-10-30T06:00:00+00:00
success 2026-10-29T06:00:00+00:00
success 2026-10-28T06:00:00+00:00
success 2026-10-27T06:00:00+00:00
ana@laptop:~/gcp$ grep -rhoE '"event":"clock_[a-z]+ ds=[^"]*' $AIRFLOW_HOME/logs | cut -d'"' -f4 | sort
clock_interval ds=2026-10-26 start=2026-10-26 06:00:00+00:00 end=2026-10-27 06:00:00+00:00
clock_interval ds=2026-10-27 start=2026-10-27 06:00:00+00:00 end=2026-10-28 06:00:00+00:00
clock_interval ds=2026-10-28 start=2026-10-28 06:00:00+00:00 end=2026-10-29 06:00:00+00:00
clock_interval ds=2026-10-29 start=2026-10-29 06:00:00+00:00 end=2026-10-30 06:00:00+00:00
clock_trigger ds=2026-10-26 start=2026-10-26 06:00:00+00:00 end=2026-10-26 06:00:00+00:00
clock_trigger ds=2026-10-27 start=2026-10-27 06:00:00+00:00 end=2026-10-27 06:00:00+00:00
clock_trigger ds=2026-10-28 start=2026-10-28 06:00:00+00:00 end=2026-10-28 06:00:00+00:00
clock_trigger ds=2026-10-29 start=2026-10-29 06:00:00+00:00 end=2026-10-29 06:00:00+00:00
clock_trigger ds=2026-10-30 start=2026-10-30 06:00:00+00:00 end=2026-10-30 06:00:00+00:00
```

**Catching up made every missed run at once.** The DAGs start on the 26th and the file appeared on
the evening of the 30th, so with `catchup=True` the scheduler created a run for each night it had
missed, the moment it read the file, and ran them all. **The two DAGs disagree on what those nights
were.** `clock_trigger` made five runs, one for each 03:00 from the 26th to the 30th, and each one's
`ds` is the night it fired, with a start and an end that are the same moment. `clock_interval` made
four, and each one's `ds` is the day it covers: the run that fired at 03:00 on the 30th has `ds`
2026-10-29 and an interval from the 29th to the 30th. The run for the 30th does not exist yet,
because the 30th's day does not end until 03:00 on the 31st.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 285\" role=\"img\" aria-label=\"Two timelines over five nights, 26 to 30 October at 03:00 in São Paulo. On the first, Airflow 3's default cron schedule, a run starts at each 03:00 and is given that night's date: ds=26 on the 26th through ds=30 on the 30th, five runs. On the second, the CronDataInterval timetable, each run covers a day from one 03:00 to the next and starts when that day ends: the run for ds=26 starts on the 27th, and the last, ds=29, on the 30th, four runs.\" data-fig=\"l24-clocks\"><line x1=\"190.0\" y1=\"40.0\" x2=\"190.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"190.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">26 Oct, 03:00</text><line x1=\"300.0\" y1=\"40.0\" x2=\"300.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"300.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">27 Oct, 03:00</text><line x1=\"410.0\" y1=\"40.0\" x2=\"410.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"410.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">28 Oct, 03:00</text><line x1=\"520.0\" y1=\"40.0\" x2=\"520.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"520.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">29 Oct, 03:00</text><line x1=\"630.0\" y1=\"40.0\" x2=\"630.0\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 3\"></line><text x=\"630.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30 Oct, 03:00</text><text x=\"20.0\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Airflow 3 default</text><text x=\"20.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a run at each 03:00</text><circle cx=\"190.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"190.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=26</text><circle cx=\"300.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"300.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=27</text><circle cx=\"410.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"410.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=28</text><circle cx=\"520.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"520.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=29</text><circle cx=\"630.0\" cy=\"100\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"630.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=30</text><text x=\"20.0\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">CronDataInterval</text><text x=\"20.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a run when a day ends</text><rect x=\"193.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=26</text><circle cx=\"300.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"303.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=27</text><circle cx=\"410.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"413.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=28</text><circle cx=\"520.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><rect x=\"523.0\" y=\"180\" width=\"104\" height=\"12\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ds=29</text><circle cx=\"630.0\" cy=\"186\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"642.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the capture ran on the 30th</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a dot is when a run starts; ds is the date the run is given</text></svg>", "caption": "The same cron expression, two timetables: the default gives a run the night it starts, the interval timetable gives it the day that just ended."}
```

**That is why Quitanda's DAG says `macros.ds_add(ds, -1)`.** On the Airflow 3 default, the run at
03:00 on the 30th has `ds` 2026-10-30, a day that has three hours in it, and the job has to be told
the day before. On `CronDataIntervalTimetable` the same DAG would use `ds` directly, which is what
Airflow 2's documentation and most of the DAGs you will read assume. Either is right, as long as the
DAG knows which timetable it has; a DAG moved from Airflow 2 to 3 without that line processes, every
night, a day that has barely begun.

**`catchup=False`, the setting in Quitanda's DAG, makes only the most recent run** when a DAG is
unpaused late, rather than one for every night since the start date. It is the safe default for a
pipeline whose old nights were processed some other way, and the wrong one for a new pipeline that
is supposed to fill its history.

## Backfill: catching up on purpose

**A backfill creates runs for a range of past dates, whatever `catchup` says.** In Airflow 3 it is a
command, and `--dry-run` lists the runs it would create without creating them:

```
ana@laptop:~/gcp$ airflow backfill create --dag-id clock_interval --from-date 2026-10-20 --to-date 2026-10-23 --dry-run 2>/dev/null | grep -A20 "Runs to be"
Runs to be attempted:
+---------------------------+-----------------+------------------+
| logical_date              | partition_key   | partition_date   |
+===========================+=================+==================+
| 2026-10-20 06:00:00+00:00 |                 |                  |
+---------------------------+-----------------+------------------+
| 2026-10-21 06:00:00+00:00 |                 |                  |
+---------------------------+-----------------+------------------+
| 2026-10-22 06:00:00+00:00 |                 |                  |
+---------------------------+-----------------+------------------+
```

**Four days were asked for, and three runs came back.** The 20th, 21st and 22nd ran from 06:00 UTC,
three in the morning in São Paulo; the 23rd did not, because `--to-date 2026-10-23` means midnight
UTC on the 23rd, six hours before that night's run would start. A backfill's dates are moments, not
days, and a range meant to include a night has to reach past that night's 03:00. Without `--dry-run`, the same command creates the three runs and the scheduler runs them, at most a
few at a time, each with its own interval. That is how a week of nights that failed because a bucket was
empty gets re-run in one command once the bucket is filled.

**This is the feature teams miss first when they leave Airflow.** Nothing in Workflows or Cloud
Scheduler knows what "the run for the 22nd" means: the workflow of the previous section computed its day
from the clock, so re-running the 22nd there means starting it with the day passed in by hand.

## Composer, or Workflows and Cloud Scheduler

**Choose by the number and the shape of the pipelines, not by the size of the data**, because
neither does the heavy work: both start Dataproc, BigQuery or Dataflow and wait.

| | Composer | Workflows with Cloud Scheduler |
|---|---|---|
| idle cost | 523.85 to 838.41 a month, the two environments of the section on the idle bill | nothing between runs |
| which day a run is for | logical date and data interval | the clock |
| catch-up and backfill | built in | an execution per day, by hand |
| pipeline written as | Python | YAML |
| services outside Google | many operators | an HTTP call |
| what you operate | the environment's size, its packages, its upgrades | the definitions |

**For Quitanda today, with one pipeline of four steps, Workflows with Cloud Scheduler is the
answer**: the same order, a retry policy where it is wanted, and no five hundred dollars a month for
a scheduler that waits. The day there are thirty DAGs, three teams and a habit of re-running last
week, the table turns, and moving to Composer is work the team will be glad of rather than a cost it
resents. Writing the first pipeline so that each step is its own job with its date as an argument,
as `daily_orders.py` takes `--dt`, is what keeps that move cheap: the jobs stay, and only the thing
that starts them changes.
