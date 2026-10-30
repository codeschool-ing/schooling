---
title: The bytes a query will be billed, computed
version: 1
---

**Before a query runs, three things fix what it will be billed on demand: the columns it references,
the partitions its filter keeps, and the types of those columns.** Nothing else does. Not the rows it
returns, not the filters on other columns, not how hard the engine has to work. That makes the bill
computable in advance, and BigQuery computes it: the dry run of the next section is that computation,
done by Google. This lab cannot ask Google, so this section writes the same computation as a program,
from the documented sizes of lesson 13 and the rules of lesson 14.

## The program

**It is a dry run you can read.** Give it a table, the columns a query references and the range of
days its partition filter keeps, and it prints the bytes BigQuery would process and bill. Save it as
`~/gcp/bqbill.py`:

```schooling-example
{"language": "python", "file": "bqbill.py", "parts": [{"code": "import math\nimport sys\n\nimport duckdb\n\nPRICE_PER_TIB, MB, TIB = 11.25, 2**20, 2**40  # on demand, southamerica-east1, read 2026-10-30\nFIXED = {'BIGINT': 8, 'DOUBLE': 8, 'DATE': 8, 'TIMESTAMP WITH TIME ZONE': 8, 'BOOLEAN': 1}\n\n", "note": "**The documented sizes, keyed by DuckDB's names for the types.** `BIGINT` is `INT64`, `DOUBLE` is `FLOAT64`, `BOOLEAN` is `BOOL`, and `TIMESTAMP WITH TIME ZONE` is `TIMESTAMP`. `VARCHAR`, BigQuery's `STRING`, is not here because its size depends on each value."}, {"code": "table, columns = sys.argv[1], sys.argv[2].split(',')\nfirst, last = (sys.argv[3], sys.argv[4]) if len(sys.argv) > 4 else ('0001-01-01', '9999-12-31')\n\n", "note": "**A query is described the way BigQuery bills it**: a table, every column the query references anywhere, and the range of `dt` its partition filter keeps. No other filter is accepted, because no other filter changes the bytes billed; that is the whole point of the program."}, {"code": "con = duckdb.connect()\ncon.sql(f\"CREATE VIEW t AS SELECT * FROM read_parquet(\"\n        f\"'warehouse/{table}/**/*.parquet', hive_partitioning = true)\")\ntypes = dict(con.sql(\"SELECT column_name, column_type FROM (DESCRIBE t)\").fetchall())\n\n", "note": "**The types come from the files**, through the same view `ask.py` makes, so a column added to the table is priced by its own type without a change here."}, {"code": "sizes = []\nfor column in columns:\n    if types[column] == 'VARCHAR':\n        sizes.append(f\"coalesce(sum(2 + strlen({column})), 0)\")\n    else:\n        sizes.append(f\"{FIXED[types[column]]} * count({column})\")\nlogical = con.sql(f\"SELECT {' + '.join(sizes)} FROM t \"\n                  f\"WHERE dt BETWEEN DATE '{first}' AND DATE '{last}'\").fetchone()[0]\n\n", "note": "**Lesson 13's rule, written as SQL for each column.** A string is 2 bytes plus its UTF-8 length; anything else is its fixed size times `count(column)`, which skips `NULL`s, because a `NULL` counts 0 bytes. Only the rows of the partitions kept are counted."}, {"code": "billed = math.ceil(max(logical, 10 * MB) / MB) * MB\nprint(f'{len(columns)} columns of {table}, {first} to {last}')\nprint(f'  bytes processed {logical:>15,}')\nprint(f'  bytes billed    {billed:>15,}   {billed / TIB * PRICE_PER_TIB:.6f} USD')\n", "note": "**Processed and billed are the two numbers BigQuery reports for a job**, `total_bytes_processed` and `total_bytes_billed`, and the minimum and the rounding are the difference between them. This program handles one table; a join is priced by running it once per table and adding the results."}]}
```

## Three queries, priced before they run

The dashboard's question, store 7 yesterday, references `dt`, `store_id` and `total_cents` for one
day. September's sales per district reference `dt`, `district` and `total_cents` for 29 days. And
`SELECT *` references all nine columns, with no partition filter:

```
ana@laptop:~/gcp$ python3 bqbill.py orders dt,store_id,total_cents 2026-09-29 2026-09-29
3 columns of orders, 2026-09-29 to 2026-09-29
  bytes processed         392,616
  bytes billed         10,485,760   0.000107 USD
ana@laptop:~/gcp$ python3 bqbill.py orders dt,district,total_cents 2026-09-01 2026-09-29
3 columns of orders, 2026-09-01 to 2026-09-29
  bytes processed      15,023,069
  bytes billed         15,728,640   0.000161 USD
ana@laptop:~/gcp$ python3 bqbill.py orders order_id,customer_id,store_id,district,items,total_cents,payment,created_at,dt
9 columns of orders, 0001-01-01 to 9999-12-31
  bytes processed      99,177,572
  bytes billed         99,614,720   0.001019 USD
```

**The dashboard processes 392,616 bytes and is billed 10,485,760**, the minimum, as lesson 15 found by
another route. **September per district processes 15,023,069 bytes** and is billed 15,728,640: the
rounding up to the next MB adds 705,571 bytes, and at this size rounding is the only difference between
the two numbers. **`SELECT *` processes the 99,177,572 bytes lesson 13 counted column by column**,
which is the same rule arriving at the same total by a different path, and a check on both.

**Every column referenced counts, wherever it is referenced.** The district query names `dt` only in its
`WHERE`, and `dt` is still 8 bytes a row of the 29 days, 4,759,056 bytes of the 15,023,069. A column
used only to filter is read like any other, because the engine has to look at it to filter on it. The
one exception is the partitioning column's effect: it decides which rows are counted at all.

## What it leaves out, deliberately

**It knows nothing of clustering**, which is why it is an honest dry run: the dry run cannot see the
blocks a cluster filter will skip either, and both print an upper bound for a clustered table. **It
treats a join as two tables**, each with its own minimum, so a join of `orders` with a table of sixteen
stores is the two runs added together. **It ignores the cache**, which would bill nothing for a
repeated query on an unchanged table, and **the free TiB**, which comes off the month rather than off
any one query. And it is DuckDB's view of a column's type, mapped to BigQuery's by the table at the
top; a type it has no entry for stops it with an error rather than a guess, which is the right way for
a cost calculator to fail.

**What it shares with the real thing is the property that makes either worth having**: the number is
known before anything is read, so a query can be refused, rewritten or allowed while it is still only
text.
