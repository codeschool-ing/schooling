---
title: The first run, and where it went
version: 1
---

```
ana@vm:~/etl/shop$ dbt run
06:26:58  Running with dbt=1.12.5
06:26:59  Registered adapter: postgres=1.11.0
06:26:59  Unable to do partial parsing because saved manifest not found. Starting full parse.
06:27:00  Found 4 models, 3 sources, 477 macros
06:27:00  
06:27:00  Concurrency: 4 threads (target='dev')
06:27:00  
06:27:00  2 of 4 START sql view model dbt_staging.stg_order_lines ........................ [RUN]
06:27:00  3 of 4 START sql view model dbt_staging.stg_orders ............................. [RUN]
06:27:00  1 of 4 START sql view model dbt_staging.stg_books .............................. [RUN]
06:27:00  1 of 4 OK created sql view model dbt_staging.stg_books ......................... [CREATE VIEW in 0.16s]
06:27:00  2 of 4 OK created sql view model dbt_staging.stg_order_lines ................... [CREATE VIEW in 0.17s]
06:27:00  3 of 4 OK created sql view model dbt_staging.stg_orders ........................ [CREATE VIEW in 0.18s]
06:27:00  4 of 4 START sql table model dbt_marts.daily_sales ............................. [RUN]
06:27:00  4 of 4 OK created sql table model dbt_marts.daily_sales ........................ [SELECT 6195 in 0.09s]
06:27:00  
06:27:00  Finished running 1 table model, 3 view models in 0 hours 0 minutes and 0.38 seconds (0.38s).
06:27:00  
06:27:00  Completed successfully
06:27:00  
06:27:00  Done. PASS=4 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=4
```

Four models, and the order is the one the `ref`s imply: the three views first, at the same time —
the project allows four threads, and nothing among them depends on anything else — and
`daily_sales` only once all three were done. `SELECT 6195` is the number of rows the table was
built with.

But look at the schemas: `dbt_staging` and `dbt_marts`, not `staging` and `marts`.

```
ana@vm:~/etl$ psql -d wh -c "\dn"
         List of schemas
    Name     |       Owner       
-------------+-------------------
 dbt_marts   | ana
 dbt_staging | ana
 marts       | ana
 public      | pg_database_owner
 raw         | ana
 staging     | ana
(6 rows)
```

**This is dbt's default, and it is deliberate.** A custom `+schema` is *added* to the target's
schema, not put in its place: `dbt` from the profile, then `_staging`. The reason is a team. Each
person's profile names their own target schema — `dbt_ana`, `dbt_rui` — and everybody can build
the whole project at once without overwriting anybody else, or production. Lesson 18 uses exactly
that to keep a development warehouse apart from the real one. The behaviour lives in a macro called
`generate_schema_name`, and a project can replace it; Ana does not, because here it gives her
something she wants.

Her old pipeline built `staging` and `marts`, and it is still there. So for now the two run side by
side, and **the first thing Ana does with the new one is check it against the old**:

```
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) FROM (TABLE marts.daily_sales EXCEPT TABLE dbt_marts.daily_sales) AS old_only" -c "SELECT count(*) FROM (TABLE dbt_marts.daily_sales EXCEPT TABLE marts.daily_sales) AS new_only"
 count 
-------
     0
(1 row)

 count 
-------
     0
(1 row)
```

`EXCEPT` in both directions, and nothing on either side: the same rows, the same numbers. A rewrite
that has not been compared with what it replaces has not been tested, however clean it looks.
