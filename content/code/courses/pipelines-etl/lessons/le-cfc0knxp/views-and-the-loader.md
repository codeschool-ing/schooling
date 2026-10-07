---
title: A view holds on to its table
version: 1
---

The next day of trade arrives, and Ana loads `raw` as she has every day since lesson 6:

```
ana@vm:~/etl$ sudo shop day 2026-03-10
ana@vm:~/etl$ python load_raw.py
raw.shops: 7 rows
Traceback (most recent call last):
  File "/home/ana/etl/load_raw.py", line 18, in <module>
    wh.execute(f"DROP TABLE IF EXISTS raw.{table}")
    ~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/etl/py/lib/python3.13/site-packages/psycopg/connection.py", line 304, in execute
    raise ex.with_traceback(None)
psycopg.errors.DependentObjectsStillExist: cannot drop table raw.books because other objects depend on it
DETAIL:  view dbt_staging.stg_books depends on table raw.books
HINT:  Use DROP ... CASCADE to drop the dependent objects too.
```

**The loader that worked yesterday fails today, and nothing in it changed.** What changed is that
`raw.books` now has a view built on it. In PostgreSQL a view is bound to the table it reads, not to
its name: the table cannot be dropped while the view exists, because the view would be left
pointing at nothing. `DROP … CASCADE` would drop the view with it — and dbt's staging would
silently disappear until the next `dbt run`.

The failure cost nothing, though. The loader writes the warehouse in a single transaction,
committed when the `with` block ends, so `raw.shops`, already recreated, was rolled back with
everything else, and `raw` is exactly as it was before the command.

The fix is in the loader, not in dbt. **A table that other things are built on is emptied and
refilled, never dropped**:

```
ana@vm:~/etl$ diff /tmp/load_raw.before.py load_raw.py
18,19c18,20
<         wh.execute(f"DROP TABLE IF EXISTS raw.{table}")
<         wh.execute(f"CREATE TABLE raw.{table} ({columns})")
---
>         # Emptied and refilled, never dropped: dbt's views are built on these tables.
>         wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{table} ({columns})")
>         wh.execute(f"TRUNCATE raw.{table}")
29,30c30,31
<         wh.execute(f"DROP TABLE IF EXISTS raw.{name}")
<         wh.execute(f"CREATE TABLE raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")
---
>         wh.execute(f"CREATE TABLE IF NOT EXISTS raw.{name} (doc jsonb NOT NULL, file text NOT NULL)")
>         wh.execute(f"TRUNCATE raw.{name}")
ana@vm:~/etl$ python load_raw.py
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5271 rows
raw.orders: 19700 rows
raw.order_lines: 30850 rows
raw.payments: 19700 rows
raw.prices: 0 documents
raw.events: 26334 documents
```

`CREATE TABLE IF NOT EXISTS` makes the table the first time and does nothing after that, and
`TRUNCATE` empties it. Two consequences come with it. `TRUNCATE` takes the same exclusive lock
lesson 7 described, so a query on a staging view waits until the loader commits rather than
seeing an empty table. And the columns are now fixed by the first load: **if the shop adds a column,
`raw` will not grow it on its own**, and the `COPY` fails with a column count that does not match.
That failure is loud, which is the right kind; lesson 16 is about making changes like it a contract
rather than a surprise.
