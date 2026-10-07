---
title: The full load
version: 1
---

The simplest extraction copies the whole table, every time. **It throws away what the warehouse
had and replaces it with what the source has now**, so it is right by construction: every insert,
every update and every delete since the last run is in the new copy, without the pipeline having
to know which happened.

Ana's full extraction of the shop's customers empties `raw.customers` and fills it again with
`COPY`, in one transaction, so a reader sees the old copy or the new one and never an empty table
in between:

```
"""Replace raw.customers with a complete copy of the shop's customers."""
import psycopg

with psycopg.connect("dbname=shop") as shop, psycopg.connect("dbname=wh") as wh:
    wh.execute("""CREATE TABLE IF NOT EXISTS raw.customers (
                    customer_id integer, name text, email text, city text, state text,
                    created_at timestamptz, updated_at timestamptz)""")
    wh.execute("TRUNCATE raw.customers")
    src, dst = shop.cursor(), wh.cursor()
    with src.copy("COPY customers TO STDOUT") as out, \
         dst.copy("COPY raw.customers FROM STDIN") as into:
        for chunk in out:
            into.write(chunk)
print(f"raw.customers: {src.rowcount} rows, all of them")
```

On the first two nights:

```
ana@vm:~/etl$ python full_customers.py
raw.customers: 5098 rows, all of them
```

```
ana@vm:~/etl$ python full_customers.py
raw.customers: 5119 rows, all of them
```

Twenty-one new customers on 2 March, and to find them the pipeline read 5,119 rows. **The cost of a
full load grows with the table, not with the change.** For customers that is fine: five thousand
rows copy in a blink and will for years. The shop's orders grow by two or three hundred a day and
never shrink, so a full load of them reads the whole history every night to find one day of news.
On 1 March that is seventeen thousand rows; in five years it is half a million, read nightly for
the sake of three hundred.

## When the full load is the right answer

- **The table is small**, and will stay small: shops, categories, a currency table, the 1,200 books.
- **The source cannot say what changed**: no `updated_at`, no log, a file that is always the whole
  catalogue. Then there is no alternative short of comparing every row, and comparing every row
  *is* a full load.
- **Deletes matter and nothing records them.** The last section of this lesson shows why that one
  is decisive.

A full load is also the safe first version of any pipeline, and the one to fall back to when an
incremental one is suspected of drifting: reload the table whole, compare, and see what the
incremental version had been missing.
