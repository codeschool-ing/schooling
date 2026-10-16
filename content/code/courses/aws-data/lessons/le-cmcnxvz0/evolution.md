---
title: When the files change shape
version: 1
---

**Changing the table is one request; changing the files is every file.** The catalog now says eight
columns, and the 31 Parquet files of October still hold seven, because a file is written once and
nobody rewrites a month of history to add a column. So every lake ends up holding files of more
than one shape under one table, and what a query returns depends on how its reader lines them up:
**by name or by position, and with whose schema in charge**.

## A column that only November has

The first day of coupons, written into the same prefix as October. The program borrows `orders`
and `regulars` from `lake.py`, so the day looks like the others plus one column:

`coupons.py`:

```python
import datetime
import random

import pyarrow as pa
import pyarrow.parquet as pq

from lake import CURATED, filesystem, orders, regulars

day = datetime.date(2026, 11, 1)
rng = random.Random(1101)
table = orders(rng, day, regulars())
coupon = [rng.choice(['PRIMAVERA10', 'FRETEGRATIS']) if rng.random() < 0.2 else None
          for _ in range(table.num_rows)]
table = table.append_column('coupon', pa.array(coupon, pa.string()))
pq.write_table(table, f'{CURATED}/dt={day}/orders.parquet', filesystem=filesystem())
print(f'{table.num_rows:,} orders on {day}, {table["coupon"].null_count:,} of them with no coupon')
```

```
ana@laptop:~/aws$ python3 coupons.py
29,467 orders on 2026-11-01, 23,485 of them with no coupon
ana@laptop:~/aws$ python3 ask.py "SELECT dt, count(*) AS orders FROM orders WHERE dt >= '2026-10-30' GROUP BY dt ORDER BY dt"
┌────────────┬────────┐
│     dt     │ orders │
│  varchar   │ int64  │
├────────────┼────────┤
│ 2026-10-30 │  21249 │
│ 2026-10-31 │  31258 │
│ 2026-11-01 │  29467 │
└────────────┴────────┘

read from S3: 196,608 bytes in 3 GET requests to 3 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py "SELECT count(coupon) FROM orders WHERE dt = '2026-11-01'"
Binder Error: Referenced column "coupon" not found in FROM clause!
Candidate bindings: "hour", "total_cents"
```

**The new day is counted, and its new column cannot be asked for.** The first `ask.py` saw
1 November like any other partition, and read only 196,608 bytes, three footers and no column at
all, because a row count is in the footer. The second refused `coupon` outright. `ask.py` builds each
table with PyArrow's default, which takes the schema from the first file it finds, `dt=2026-10-01`,
and that file has no coupons. **The reader decided the schema, and it decided from October.**

That is a simplification of this course's program, and it is the commonest one in the wild. Athena
does not make it: it takes the schema from the catalog, version 2 onwards lists `coupon`, and
Parquet is read by name, so October would answer `NULL` for every coupon and November its values.
That was not run, since moto runs no SQL. What DuckDB does with the two files directly can be run,
once they are copied out of moto:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/orders/dt=2026-10-31/orders.parquet oct31.parquet --only-show-errors
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/orders/dt=2026-11-01/orders.parquet nov01.parquet --only-show-errors
ana@laptop:~/aws$ python3 -c "import duckdb; duckdb.sql(\"SELECT count(*) AS orders, count(coupon) AS with_coupon FROM read_parquet(['oct31.parquet', 'nov01.parquet'], union_by_name = true)\").show()"
┌────────┬─────────────┐
│ orders │ with_coupon │
│ int64  │    int64    │
├────────┼─────────────┤
│  60725 │        5982 │
└────────┴─────────────┘

ana@laptop:~/aws$ python3 -c "import duckdb; duckdb.sql(\"SELECT count(coupon) FROM read_parquet(['oct31.parquet', 'nov01.parquet'])\").show()"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
_duckdb.BinderException: Binder Error: Referenced column "coupon" not found in FROM clause!
Candidate bindings: "hour", "total_cents"
```

**`union_by_name = true` lines the files up by column name**, and the column one of them lacks comes
back empty: 60,725 orders, 5,982 of them with a coupon, which is 29,467 minus the 23,485 `coupons.py`
counted without one. Leave it out and DuckDB does what PyArrow did, and takes the first file's
columns. Every engine has this switch somewhere, named differently, and the default is rarely the
one a lake needs.

## A column that changes type

The other change from the previous section, the total in reais. A new version of the export writes
2 November with `total_cents` as a decimal number:

`reais.py`:

```python
import pyarrow as pa
import pyarrow.compute as pc
import pyarrow.parquet as pq

from lake import CURATED, filesystem

s3 = filesystem()
table = pq.read_table(f'{CURATED}/dt=2026-11-01/orders.parquet', filesystem=s3)
reais = pc.divide(table['total_cents'].cast(pa.float64()), 100)
table = table.set_column(table.schema.get_field_index('total_cents'), 'total_cents', reais)
pq.write_table(table, f'{CURATED}/dt=2026-11-02/orders.parquet', filesystem=s3)
print(table.schema.field('total_cents'))
```

```
ana@laptop:~/aws$ python3 reais.py
pyarrow.Field<total_cents: double>
ana@laptop:~/aws$ python3 ask.py "SELECT dt, sum(total_cents) AS total FROM orders WHERE dt >= '2026-11-01' GROUP BY dt ORDER BY dt"
Invalid Input Error: arrow_scan: get_next failed(): Invalid: Float value 265.680000 was truncated converting to int64
ana@laptop:~/aws$ aws s3 rm s3://quitanda-curated-prod/orders/dt=2026-11-02/orders.parquet
delete: s3://quitanda-curated-prod/orders/dt=2026-11-02/orders.parquet
```

**The read failed on the first total with centavos in it.** October said `int64`, the schema came
from October, and 265.68 cannot become an integer without losing something, so PyArrow refused. A
total of exactly 52.00 would have become 52, read as fifty-two cents, without a word; the refusal is
the lucky case, and the file goes before it is read by anything else.

Athena with the catalog's version 3, `double` over October's `bigint` files, refuses the other way
round, which is the `HIVE_PARTITION_SCHEMA_MISMATCH` of the previous section. Either way **a type
cannot change in place**, because the old files keep the old type for ever. The changes a lake can
take are few and they are worth knowing by heart:

| change | Parquet, read by name | CSV, read by position |
|---|---|---|
| a new column at the end | safe: old files answer `NULL` | safe: old lines are shorter |
| a new column in the middle | safe | breaks every column after it |
| a renamed column | old files lose the column | harmless to the reader, confusing to people |
| a changed type | breaks the old files | breaks the old files |

**A type changes by adding a column**, `total_reais` beside `total_cents`, or by rewriting every old
partition into the new type, which is a job, the subject of lesson 17. The catalog's versions record
what the table said; they do nothing to make the files agree.

