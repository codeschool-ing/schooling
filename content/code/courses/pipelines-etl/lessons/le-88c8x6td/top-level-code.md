---
title: The code that runs when nobody asked
version: 1
---

A DAG file is a Python program, and the DAG processor runs it — **the whole file, from the top,
every time it reads the folder**. In this lab that is every few seconds for a new file, and every
thirty seconds or so after that. The tasks run only when a run is scheduled; everything outside
them runs on every pass.

A colleague writes a DAG that makes one task per shop, by asking the shop's database which shops
exist:

```
"""One task per shop, worked out by asking the shop's database which shops exist."""
import pendulum
import psycopg
from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import dag

with psycopg.connect("dbname=shop") as shop:                 # runs on every parse
    SHOPS = shop.execute("SELECT shop_id, name FROM shops ORDER BY shop_id").fetchall()


@dag(schedule=None, start_date=pendulum.datetime(2026, 3, 1, tz="America/Sao_Paulo"))
def by_shop():
    for shop_id, name in SHOPS:
        BashOperator(task_id=f"report_shop_{shop_id}", bash_command=f"echo '{name}'")


by_shop()
```

It is tidy, and it works: seven shops, seven tasks. Now look at what parsing it costs, and what it
does to the shop's database while the DAG sits there, never run:

```
ana@vm:~/etl$ airflow dags reserialize >/dev/null 2>&1; airflow dags report
file            | duration       | dag_num | task_num | dags        
================+================+=========+==========+=============
by_shop.py      | 0:00:00.085735 | 1       | 7        | by_shop     
shop_nightly.py | 0:00:00.019797 | 1       | 6        | shop_nightly
                                                                    
ana@vm:~/etl$ psql -d shop -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = current_database()"; sleep 120; psql -d shop -Atc "SELECT xact_commit FROM pg_stat_database WHERE datname = current_database()"
731
745
```

`by_shop.py` takes more than four times as long to parse as `shop_nightly.py`, and during two quiet minutes the
shop's database committed 14 transactions, one of them the query that counted the others. **Each
parse of a DAG that has never run is a connection to the production database**, every thirty
seconds, every day, for as long as the file is in the folder — and if the database is slow or
down, the DAG processor waits on it, and every other DAG's changes wait in the queue behind.

## The rule

**At the top level of a DAG file, declare; never fetch.** Imports, constants, the DAG and its tasks —
nothing that opens a connection, reads a file that may be large, or calls an API. If the shape of a
DAG has to depend on data, read the data inside a task and fan out at run time — Airflow's *dynamic
task mapping* exists for that — or generate the DAG file from the data, in a separate step that
somebody runs on purpose.

Ana deletes `by_shop.py`. Her own DAG imports two modules and defines constants, and parses in a
fiftieth of a second.
