---
title: The logical date, and the day being loaded
version: 1
---

Every DAG run is *for* a moment, and Airflow calls that moment its **logical date**. It is not
the time the run happens to start. A run scheduled for 02:00 on 3 March has that logical date
whether it starts at 02:00:01, after a two-hour outage, or six months later when somebody reruns it
by hand. **That is what lets a pipeline reprocess the past**: a task that asks the run which date it
is for, instead of asking the clock, does the same work whenever it is run.

`day_to_load` is that rule in four lines: it takes the run's logical date, puts it in São Paulo
time, and subtracts a day. The run for 02:00 on 3 March loads 2 March, today or next year:

```
ana@vm:~/etl$ airflow dags list-runs shop_nightly -o plain
dag_id        run_id                                    state    run_after                         logical_date               start_date                 end_date
shop_nightly  manual__2026-10-07T08:26:49.538261+00:00  success  2026-10-07T08:26:49.538261+00:00  2026-03-03T03:00:00+00:00  2026-03-03T03:00:00+00:00  2026-10-07T08:26:55.648104+00:00
```

`logical_date` is `2026-03-03T03:00:00+00:00` — midnight of 3 March in São Paulo, written in UTC —
because `dags test` was given the date `2026-03-03` with no time. `run_after`, the moment the run
was allowed to start, is the real clock of the recording, in October. **The two have nothing to
do with each other**, and a task that used `run_after`, or `datetime.now()`, would have loaded a
day in October.

## The execution date, and what Airflow 3 changed

Airflow 2 called this field the **execution date**, and the name caused a decade of confusion,
because a daily run did not execute on its execution date. Its runs covered an interval — a whole
day — and ran when the interval was over, so the run for 2 March executed early on 3 March.

Airflow 3 renamed the field to *logical date*, and changed what a plain cron schedule means. By
default, `schedule="0 2 * * *"` is now a **trigger**: a run happens at 02:00, its logical date *is*
02:00, and it has no interval behind it. The old behaviour is still available, by declaring a
schedule that has intervals, and lesson 9 shows both side by side. **Ana's DAG takes the simpler
rule and says in its own code which day it loads**: the logical date minus one day. Nothing about it
depends on remembering which convention the version of Airflow in front of you uses.

Lesson 9 adds the other half: what the scheduler does with these dates when it is the scheduler,
and not `dags test`, that creates the runs.
