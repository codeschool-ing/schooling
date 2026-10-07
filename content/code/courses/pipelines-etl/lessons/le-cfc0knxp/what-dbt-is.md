---
title: What dbt does, and what it leaves to you
version: 1
---

Ana's transformations are a folder of SQL files and a shell script that runs them **in the order of
their names**. Every file begins with `DROP TABLE IF EXISTS` and a `CREATE TABLE … AS`, and the
order is right only because she named the files so that it would be. When `daily_sales` reads
`staging.books`, nothing writes that down except the alphabet.

**dbt** — the *data build tool* — takes that job. A dbt **model** is one file holding one `select`:
no `CREATE`, no `DROP`, no transaction. dbt writes the statements that turn the `select` into a
view or a table, runs them in the warehouse, and works out the order from the models themselves,
because every model names the models it reads. It moves no data between machines: everything runs
inside PostgreSQL, which makes it the T of ELT and nothing else. Extracting and loading `raw` is
still `load_raw.py`'s job, and scheduling is still Airflow's.

The lab's dbt is dbt-core with the PostgreSQL adapter, installed in its own virtual environment. Ana
starts a project in `~/etl/shop`, with the same staging and marts she already has. Its settings:

```schooling-example
{
  "language": "yaml",
  "file": "shop/dbt_project.yml",
  "parts": [
    {
      "code": "name: shop\nversion: \"1.0\"\nprofile: ponto_final            # which entry of ~/.dbt/profiles.yml to connect with\n\n",
      "note": "The project's name, which is also the first part of every model's name in `dbt ls`, and the **profile**: which connection, from a file that lives outside the project."
    },
    {
      "code": "flags:\n  send_anonymous_usage_stats: false\n  use_colors: false\n\n",
      "note": "The lab has no internet. Without the first flag dbt tries to send usage statistics on every command; without the second, its output is full of colour codes."
    },
    {
      "code": "models:\n  shop:\n",
      "note": "Settings by folder. A `+` marks a setting that applies to every model below this point."
    },
    {
      "code": "    staging:                    # everything under models/staging\n      +schema: staging\n      +materialized: view\n",
      "note": "**Staging models become views**, which cost nothing to build and always show what is in `raw` now."
    },
    {
      "code": "    marts:                      # everything under models/marts\n      +schema: marts\n      +materialized: table",
      "note": "**Marts become tables**, rebuilt on every run, because reports read them all day and a view would rerun every join each time."
    }
  ]
}
```

How to connect is kept out of the project, in `~/.dbt/profiles.yml`, so that the project can be
shared without anybody's password in it:

```
ponto_final:
  target: dev
  outputs:
    dev:
      type: postgres
      host: /run/etl-pg         # the socket's directory: a path, not a name
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt
      threads: 4
```

`schema: dbt` is where models go unless they say otherwise; the next section shows what happened to
the ones that did. The project so far is six files:

```
ana@vm:~/etl/shop$ find . -type f | sort
./dbt_project.yml
./models/marts/daily_sales.sql
./models/staging/sources.yml
./models/staging/stg_books.sql
./models/staging/stg_order_lines.sql
./models/staging/stg_orders.sql
```

And `dbt debug` checks everything before anything is built — that both files parse, that `git` is
there for packages, and that the connection works:

```
ana@vm:~/etl/shop$ dbt debug 2>&1 | grep -E "OK|ERROR|checks"
08:48:17    profiles.yml file [OK found and valid]
08:48:17    dbt_project.yml file [OK found and valid]
08:48:17   - git [OK found]
08:48:17    Connection test: [OK connection ok]
08:48:17  All checks passed!
```
