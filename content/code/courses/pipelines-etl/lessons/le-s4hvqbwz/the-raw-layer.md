---
title: A raw layer to transform
version: 1
---

Lessons 2 to 5 extracted the shop's data four different ways. **This lesson is about what happens
next**, so it starts from the simplest raw layer that holds everything: the six shop tables copied
whole, the publishers' prices as the API sent them, and every event file that has landed.

The lab plays the first week of March and starts the price API. Ana fetches every price the API
has, with the client from lesson 3, and runs the loader:

```schooling-example
{
  "language": "python",
  "file": "load_raw.py",
  "parts": [
    {
      "code": "\"\"\"Load the raw layer: the shop's tables copied whole, and the files that\nlanded — the publishers' prices and the website's events — as JSON.\"\"\"\nimport glob\n\nimport psycopg\n\n"
    },
    {
      "code": "TABLES = [\"shops\", \"books\", \"customers\", \"orders\", \"order_lines\", \"payments\"]\nCOLUMNS = \"\"\"SELECT string_agg(format('%%I %%s', attname, format_type(atttypid, atttypmod)),\n                               ', ' ORDER BY attnum)\n               FROM pg_attribute\n              WHERE attrelid = %s::regclass AND attnum > 0 AND NOT attisdropped\"\"\"\n\n",
      "note": "Six tables, and a query that asks the shop to describe each one's columns and types. **The raw table is declared from the source's own description**, so a column the shop adds next month arrives without anybody editing this file — and the staging SQL that reads it will be the place a decision is made."
    },
    {
      "code": "with psycopg.connect(\"dbname=shop\") as shop, psycopg.connect(\"dbname=wh\") as wh:\n    wh.execute(\"CREATE SCHEMA IF NOT EXISTS raw\")\n    shop.execute(\"SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY\")\n",
      "note": "One snapshot for all six tables, as lesson 3 required, so no line arrives without its order."
    },
    {
      "code": "    for table in TABLES:\n        columns = shop.execute(COLUMNS, (table,)).fetchone()[0]\n        wh.execute(f\"DROP TABLE IF EXISTS raw.{table}\")\n        wh.execute(f\"CREATE TABLE raw.{table} ({columns})\")\n",
      "note": "Each raw table is dropped and rebuilt, then filled with `COPY`. A full load, which is lesson 4's right answer for a week of a small shop."
    },
    {
      "code": "        src, dst = shop.cursor(), wh.cursor()\n        with src.copy(f\"COPY {table} TO STDOUT\") as out, \\\n             dst.copy(f\"COPY raw.{table} FROM STDIN\") as into:\n            for chunk in out:\n                into.write(chunk)\n        print(f\"raw.{table}: {src.rowcount} rows\")\n\n",
      "note": "**JSON lands as JSON.** Each line of the price file and of every event file becomes one `jsonb` value, untouched, beside the name of the file it came from. Parsing it is staging's job."
    },
    {
      "code": "    for name, pattern in [(\"prices\", \"landing/prices.jsonl\"),\n                          (\"events\", \"landing/events/*.jsonl\")]:\n        wh.execute(f\"DROP TABLE IF EXISTS raw.{name}\")\n        wh.execute(f\"CREATE TABLE raw.{name} (doc jsonb NOT NULL, file text NOT NULL)\")\n",
      "note": "`write_row` hands one row at a time to the same `COPY`, so the whole file still travels in one statement."
    }
  ]
}
```

```
ana@vm:~/etl$ python prices.py 2000-01-01T00:00:00-03:00 landing/prices.jsonl
909 prices in 5 pages, 1 waits for the rate limit
ana@vm:~/etl$ python load_raw.py
raw.shops: 7 rows
raw.books: 1200 rows
raw.customers: 5221 rows
raw.orders: 18945 rows
raw.order_lines: 29668 rows
raw.payments: 18945 rows
raw.prices: 909 documents
raw.events: 18308 documents
```

The raw layer now holds three kinds of thing, and **each will need a different transformation**:

- the shop's tables, whose rows are already well formed — they need a date worked out, and a few
  columns derived, and nothing cleaned;
- the prices, sent by several publishers' systems through one API, which disagree with each other
  about how to write an ISBN;
- the events, which arrive at least once.

## Where the SQL goes

Every transformation in this lesson is a SQL file that builds one table, and the files live in two
directories that are the two layers above `raw`:

```
sql/
  staging/   one cleaned table per raw table
  marts/     what people ask about
```

A staging file reads only `raw`; a marts file reads only `staging`. **That rule is the whole of
lesson 2's layering, enforced by where a file is allowed to sit.** The next sections write the
files one at a time; the last one builds them all in order.
