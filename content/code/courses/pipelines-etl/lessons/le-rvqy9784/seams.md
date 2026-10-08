---
title: Seams: where a test can reach in
version: 1
---

An integration test must not run against the real shop and the real warehouse: it would load real
data into production tables, and its answers would change every night. It needs databases of its
own, and the pipeline has to be told to use them. Ana's code had the names written into it —
`dbname=shop`, `dbname=wh` — so there was nowhere for a test to reach in.

A place where behaviour can be changed without changing the code is called a **seam**. Ana adds two:
an environment variable for each database, defaulting to the real ones, and a second dbt target:

```
ana@vm:~/etl$ diff /tmp/load_raw.before.py load_raw.py
3a4
> import os
13c14,17
< with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
---
> SHOP_DB = os.environ.get("SHOP_DB", "shop")   # the tests point these at their own databases
> WH_DB = os.environ.get("WH_DB", "wh")
> 
> with psycopg.connect(dbname=SHOP_DB) as shop, psycopg.connect(dbname=WH_DB) as wh:
ana@vm:~/etl$ tail -n 10 ~/.dbt/profiles.yml
      threads: 4
    test:                       # the integration tests' own warehouse
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh_test
      schema: dbt
      threads: 4
```

The nightly runs exactly as before, because nothing sets the variables and `dev` is still the default
target. The tests set `SHOP_DB=shop_test WH_DB=wh_test` and pass `--target test`. **Nothing in the
pipeline knows it is being tested**, which is the point: what the test runs is the code that runs at
night, not a copy made testable.

The same two seams are what lesson 18 needs to run the pipeline in a development environment and in
production from the same code. A test environment is simply the first environment.
