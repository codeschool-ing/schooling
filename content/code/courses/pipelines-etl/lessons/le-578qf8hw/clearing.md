---
title: Clearing a task, and running it again
version: 1
---

A failed run is not rerun by triggering a new one. A new run would be a second run for the same
night, with its own id and its own history, and the failed one would still be sitting in the list
saying the night failed. **Airflow's way is to clear the task**: its state is wiped, the run goes
back to `running`, and the scheduler gives the task another try as though the failure had been one
more retry.

`airflow tasks clear` picks task instances by DAG, by task (`-t`, a regular expression), and by
logical date (`-s` and `-e`). `--only-failed` leaves alone anything that succeeded, which matters
in a DAG with many tasks: clearing the whole run would redo work that was fine.

```
ana@vm:~/etl$ airflow tasks clear prices_daily -t fetch -s 2026-03-10T03:00:00-03:00 -e 2026-03-10T03:00:00-03:00 --only-failed -y 2>&1 | tail -n 3 | cut -c1-118
ana@vm:~/etl$ airflow dags list-runs prices_daily -o plain | cut -c1-118
dag_id        run_id                                    state    run_after                         logical_date       
prices_daily  manual__2026-10-07T08:41:45.770719+00:00  success  2026-10-07T08:41:45.770719+00:00  2026-03-10T06:00:00
prices_daily  scheduled__2026-10-07T06:00:00+00:00      success  2026-10-07T06:00:00+00:00         2026-10-07T06:00:00
ana@vm:~/etl$ RUN=$(airflow dags list-runs prices_daily -o plain | grep -o "manual__[^ ]*"); sh tries.sh prices_daily $RUN fetch
try 1 failed 08:41:46 to 08:41:46
try 2 failed 08:42:09 to 08:42:09
try 3 failed 08:43:00 to 08:43:00
try 4 failed 08:44:35 to 08:44:35
try 5 failed 08:47:31 to 08:47:31
try 6 success 08:47:51 to 08:47:52
ana@vm:~/etl$ wc -l < landing/prices.jsonl; cat alerts.log
932
2026-10-07 05:43:47 LATE prices_daily run=manual__2026-10-07T08:41:45.770719+00:00 state=running
2026-10-07 05:47:31 FAILED prices_daily.fetch run=manual__2026-10-07T08:41:45.770719+00:00 try=5 error=HTTPError('503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200')
```

With `-y` and nothing to ask, the command prints nothing. The run is `success` now, and it is still **the same run**: the same id, the same logical date,
and its history kept — five failed tries, then a sixth that worked. Nobody reading the run later
has to guess what happened that night. The prices are in `landing/prices.jsonl`, and
`alerts.log` has not grown: neither the deadline nor the failure callback had anything new to
say.

## What clearing assumes

Clearing runs the task again **with the same logical date**, and everything in this course that
reads the logical date reads the same day. `fact_sales` in `shop_nightly`, cleared, loads the same
day it failed to load, not today. That is why lesson 8 insisted that a task work out its day from
the run and never from the clock: **a task that reads the clock cannot be rerun**, because the
rerun loads whatever day it happens to be.

And it assumes, like a retry, that running the task again is safe. A clear is a retry a person
asked for. Everything the retries section said about running twice applies, with one difference: a
retry follows a failure by seconds, and a clear can follow it by days, by which time the source may
hold new data. A fetch that asks the API for *everything now* is safe to clear; one that asks for
*what changed since the last run* has to be told which last run it means.

Clearing downstream tasks too is `--downstream`: in `shop_nightly`, clearing `transform` with it
would rerun the three loads after it, which is what a fix to a staging query needs.
