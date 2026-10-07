---
title: Passing a value from one task to another
version: 1
---

`day_to_load` returned a string, and `fact_sales` used it. **A task's return value is stored in
Airflow's metadata database as an XCom** — a *cross-communication* — keyed by the run, the task and
the name `return_value`, and any later task in the same run can fetch it. Ana's small script asks
Airflow's API for one:

```
#!/bin/sh
# The value a task returned in the latest run of a DAG, asked of Airflow's API.
dag=$1 task=$2
run=$(airflow dags list-runs "$dag" -o json | python -c 'import json, sys; print(json.load(sys.stdin)[0]["run_id"])')
curl -s "http://127.0.0.1:8080/api/v2/dags/$dag/dagRuns/$run/taskInstances/$task/xcomEntries/return_value" |
  python -c 'import json, sys; x = json.load(sys.stdin); print(x["logical_date"], x["task_id"], "returned", repr(x["value"]))'
```

```
ana@vm:~/etl$ sh xcom.sh shop_nightly day_to_load
2026-03-03T03:00:00Z day_to_load returned '2026-03-02'
```

The run for 3 March stored `'2026-03-02'`. It is there for as long as the run is, so a week later
anybody can see exactly which day that run loaded, which is what somebody needs to know on the
morning they ask why a report has a gap.

## What an XCom is for

**An XCom is for a small value that decides what the next task does**: a date, a file name, a row
count, the id of something the last task created. It goes into a column of the metadata database
and is read back as JSON, so it should be measured in bytes, not megabytes.

What it is not for is data. A task that returns a list of a million orders so that the next task
can load them has put a million orders into Airflow's own database, between two tasks that could
have shared a table. **Data moves through the warehouse; XComs carry the labels on it.** Ana's tasks
never pass rows: `extract` writes `raw`, `transform` reads it, and the only thing that moves through
Airflow is one date.
