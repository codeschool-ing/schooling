---
title: Assets: running when the data changes
version: 1
---

The sales report should run after the fact table is loaded. Scheduling it at 04:00, two hours after
the nightly load starts, works until the night the load takes three hours — and then the report
runs on yesterday's table and succeeds. **What the report depends on is not a time but an event: the
fact table has new data.**

Airflow 3 lets a DAG say that. A task declares that it produces an **asset** — a name for a piece of
data, written as a URI — and another DAG declares that it runs whenever that asset is updated. Ana
marks `fact_sales` as producing the fact table:

```
ana@vm:~/etl$ sed -i 's|^from airflow.sdk import dag, task|from airflow.sdk import Asset, dag, task|' dags/shop_nightly.py
ana@vm:~/etl$ sed -i 's|-f load/fact_sales.sql",|-f load/fact_sales.sql",\n                              outlets=[Asset("postgres://localhost:5432/wh/marts/fact_sales")],|' dags/shop_nightly.py
ana@vm:~/etl$ grep -n -A3 "fact_sales = " dags/shop_nightly.py
32:    fact_sales = BashOperator(task_id="fact_sales",
33-                              bash_command=f"{PSQL} -v day={day} -f load/fact_sales.sql",
34-                              outlets=[Asset("postgres://localhost:5432/wh/marts/fact_sales")],
35-                              cwd=ETL)
```

and writes a report that is scheduled on the asset rather than on a clock:

```
"""A report that runs whenever the fact table has been loaded, whoever loaded it."""
import pendulum
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import Asset, dag

FACT_SALES = Asset("postgres://localhost:5432/wh/marts/fact_sales")


@dag(schedule=[FACT_SALES], start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def sales_report():
    BashOperator(task_id="report", bash_command=(
        "psql -d wh -Atc \"SELECT max(order_date), sum(line_cents) FROM marts.fact_sales\""))


sales_report()
```

Airflow now knows the asset, and the report waits for it:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags unpause sales_report; airflow assets list
dag_id       | is_paused
=============+==========
sales_report | True     
                        
name                                          | uri                                           | group | extra
==============================================+===============================================+=======+======
postgres://localhost:5432/wh/marts/fact_sales | postgres://localhost:5432/wh/marts/fact_sales | asset | {}   
                                                                                                             
ana@vm:~/etl$ sudo shop day 2026-03-09
ana@vm:~/etl$ airflow backfill create --dag-id shop_nightly --from-date 2026-03-10 --to-date 2026-03-10T12:00:00-03:00 2>&1 | grep -c "Created backfill Dag run"
1
ana@vm:~/etl$ airflow dags list-runs sales_report -o plain | cut -c1-118
dag_id        run_id                                                      state    run_after                         l
sales_report  asset_triggered__2026-10-07T08:34:50.666554+00:00_Hc3BvPDZ  success  2026-10-07T08:34:50.666554+00:00   
ana@vm:~/etl$ f=$(ls -d ~/airflow/logs/dag_id=sales_report/run_id=*/task_id=report | head -1); grep -oE "\"event\":\"[0-9-]+\|[0-9]+\"" $f/attempt=1.log
"event":"2026-03-09|23133780"
```

`shop day` plays 9 March, and a backfill loads it. When `fact_sales` succeeded, Airflow recorded an
event on the asset, and the scheduler started `sales_report` — `asset_triggered`, at the moment the
load finished, with no time written anywhere. The report saw 9 March, and the total of everything
loaded so far.

## What an asset is, and is not

**An asset is a promise, not a check.** Airflow records that `fact_sales` *said* it updated the
table; it does not look at the table. A task that declares an outlet and writes nothing still
triggers the report. The URI is a name that two DAGs agree on — Airflow's PostgreSQL provider insists
it have a host, a port, a database, a schema and a table, which is why it reads `localhost:5432`
although nothing connects there.

**And it joins DAGs that different people own.** The person who writes the report does not need to
know when, how or by which DAG the fact table is loaded — only its name. That is the same
separation lesson 2 drew between layers, drawn between teams.
