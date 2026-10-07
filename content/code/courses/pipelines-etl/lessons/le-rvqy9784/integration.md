---
title: The whole nightly, on one real day
version: 1
---

The integration test builds `shop_test` from the fixture, runs the real loader and the real dbt
project into `wh_test`, and checks three things:

```
"""Integration tests: the whole nightly, on one real day of the shop, in databases
of its own. The answers are worked out from the fixture directly, by queries that
share no code with the pipeline."""
import os
import subprocess

import psycopg
import pytest

ETL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DAY = "2026-03-02"


def sh(cmd, **env):
    subprocess.run(cmd, shell=True, check=True, cwd=env.pop("cwd", ETL),
                   env={**os.environ, **env}, stdout=subprocess.DEVNULL)


@pytest.fixture(scope="module")
def warehouse(tmp_path_factory):
    """Build shop_test from the fixture, then run the nightly into wh_test."""
    fixture = os.path.join(ETL, "tests", "fixture")
    sh("dropdb --if-exists --force shop_test; createdb shop_test; "
       f"psql -q -d shop_test -f {fixture}/schema.sql")
    for table in ["shops", "books", "customers", "orders", "order_lines", "payments"]:
        sh(f"psql -q -d shop_test -c \"\\copy {table} FROM '{fixture}/{table}.csv' "
           "WITH (FORMAT csv, HEADER)\"")
    sh("dropdb --if-exists --force wh_test; createdb wh_test")
    empty = tmp_path_factory.mktemp("landing")           # no prices and no events today
    sh(f"python {ETL}/load_raw.py", SHOP_DB="shop_test", WH_DB="wh_test", cwd=empty)
    sh("dbt build --project-dir shop --target test --quiet")
    with psycopg.connect("dbname=shop_test") as shop, psycopg.connect("dbname=wh_test") as wh:
        yield shop, wh


def one(conn, sql):
    return conn.execute(sql).fetchone()


def test_every_completed_line_of_the_day_is_one_fact_row(warehouse):
    shop, wh = warehouse
    expected = one(shop, "SELECT count(*), sum(l.quantity * l.unit_price_cents) "
                         "FROM order_lines l JOIN orders o USING (order_id) "
                         "WHERE o.status = 'completed'")
    got = one(wh, f"SELECT count(*), sum(line_cents) FROM dbt_marts.fact_sales "
                  f"WHERE order_date = '{DAY}'")
    assert got == expected


def test_daily_sales_adds_up_to_the_fact_table(warehouse):
    _, wh = warehouse
    daily = one(wh, "SELECT sum(books), sum(revenue_cents) FROM dbt_marts.daily_sales")
    facts = one(wh, "SELECT sum(quantity), sum(line_cents) FROM dbt_marts.fact_sales")
    assert daily == facts


def test_a_second_build_changes_nothing(warehouse):
    _, wh = warehouse
    fingerprint = ("SELECT md5(string_agg(f::text, chr(10) ORDER BY order_id, line_no)) "
                   "FROM dbt_marts.fact_sales f")
    before = one(wh, fingerprint)
    sh("dbt build --project-dir shop --target test --quiet")
    assert one(wh, fingerprint) == before
```

In the first test, the expected answer is the part that matters. It is
**worked out from the fixture directly**, by a query on `orders` and `order_lines` that shares no
code with the pipeline: no staging view, no `int_sales`, no dbt. If the pipeline and the oracle were
the same code, a bug in it would agree with itself. The second checks that the mart adds up to the
fact table it summarises. The third is lesson 15's idempotency test, made part of the suite.

The first time Ana ran it, it did not finish. After a minute she looked at what the test warehouse
was doing:

```
-- Who is connected to the test warehouse, and what each one is doing or waiting for.
SELECT pid, application_name AS app, state, wait_event_type AS waiting,
       left(regexp_replace(query, '^/[*][^*]*[*]/\s*', ''), 46) AS query
  FROM pg_stat_activity
 WHERE datname = 'wh_test' AND pid <> pg_backend_pid()
 ORDER BY pid;
```

```
ana@vm:~/etl$ timeout 150 python -m pytest -q tests/test_nightly.py > /tmp/pytest.out 2>&1 &
ana@vm:~/etl$ psql -d wh_test -f waiting.sql
  pid  | app |        state        | waiting |                     query                      
-------+-----+---------------------+---------+------------------------------------------------
 10378 |     | idle in transaction | Client  | SELECT md5(string_agg(f::text, chr(10) ORDER B
 10428 | dbt | active              | Lock    | alter table "wh_test"."dbt_marts"."daily_sales
(2 rows)

ana@vm:~/etl$ cat /tmp/pytest.out; echo
..
```

Two connections. One is the test's own, **idle in transaction**. Its last query, the `md5` of the
third test, has finished, but psycopg opens a transaction with the first query on a connection and
keeps it open until it is committed. The second test had read `daily_sales` in that same
transaction. The other is dbt, in the middle of the second build, **waiting for a lock** to rename
`daily_sales` into place. Each was waiting for the other: dbt for the test's transaction to end, the
test for dbt to finish. PostgreSQL detects deadlocks between its own sessions, but this one has one
side outside the database — a Python process waiting for a child to exit — so nothing broke it. Two
tests had passed (`..`), and the third would have waited for ever if `timeout` had not ended it.

This is lesson 7's lesson about locks, found by a test rather than by a manager's report freezing at
eight in the morning. The fix is to read without a transaction left open:

```
ana@vm:~/etl$ grep -n -B1 -A1 "autocommit=True" tests/test_nightly.py
32-    # autocommit: a test that only reads must not hold locks the next build waits for
33:    with psycopg.connect("dbname=shop_test", autocommit=True) as shop, \
34:         psycopg.connect("dbname=wh_test", autocommit=True) as wh:
35-        yield shop, wh
```

```
ana@vm:~/etl$ time python -m pytest -q tests/test_nightly.py 2>&1 | tail -n 3
...                                                                      [100%]
3 passed in 7.87s

real	0m8.099s
user	0m7.193s
sys	0m0.427s
```

Three passed, in under eight seconds. Then the whole suite, unit and integration together:

```
ana@vm:~/etl$ python -m pytest -q tests
..........                                                               [100%]
10 passed in 7.82s
done
```

Ten tests, and the integration suite's first run found a bug in the test rather than in the
pipeline. That happens, and it is still worth finding: a test that hangs is a test nobody runs.
