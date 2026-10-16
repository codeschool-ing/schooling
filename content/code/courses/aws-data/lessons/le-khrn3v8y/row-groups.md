---
title: Row groups, and the statistics that skip them
version: 1
---

**Inside a Parquet file, a filter on a column can skip blocks of rows without reading them**, and the
footer is what makes it possible. Each column chunk of each row group carries the smallest and the
largest value it holds. A reader asked for `hour >= 21` reads the footer first, and any group whose
largest hour is below 21 cannot hold a single matching row, so its chunks are never fetched. This is
called predicate pushdown, and Athena's engine does it for Parquet and ORC as DuckDB and PyArrow do.

**It works only if the values are clustered.** A group's range says something only when the rows in
it are alike. The `groups` layout and the `groups-shuffled` layout hold the same rows in groups of
2,000; one keeps the order of the day, the other does not. `footer.py`, from lesson 15, prints each
group's range:

```
ana@laptop:~/aws$ python3 footer.py s3://quitanda-curated-prod/layouts/groups/dt=2026-10-15/orders.parquet | grep -E 'rows|hour'
23,781 rows in 12 row groups, footer 9,494 bytes
  0  hour                 101 bytes             7 .. 10
  1  hour                  88 bytes            10 .. 11
  2  hour                  88 bytes            11 .. 12
  3  hour                  94 bytes            12 .. 14
  4  hour                  95 bytes            14 .. 16
  5  hour                  95 bytes            16 .. 18
  6  hour                  88 bytes            18 .. 19
  7  hour                  81 bytes            19 .. 19
  8  hour                  88 bytes            19 .. 20
  9  hour                  88 bytes            20 .. 21
  10  hour                  88 bytes            21 .. 22
  11  hour                  88 bytes            22 .. 23
```

```
ana@laptop:~/aws$ python3 footer.py s3://quitanda-curated-prod/layouts/groups-shuffled/dt=2026-10-15/orders.parquet | grep -E 'rows|hour'
23,781 rows in 12 row groups, footer 9,496 bytes
  0  hour               1,404 bytes             7 .. 23
  1  hour               1,404 bytes             7 .. 23
  2  hour               1,404 bytes             7 .. 23
  3  hour               1,404 bytes             7 .. 23
  4  hour               1,404 bytes             7 .. 23
  5  hour               1,404 bytes             7 .. 23
  6  hour               1,404 bytes             7 .. 23
  7  hour               1,404 bytes             7 .. 23
  8  hour               1,404 bytes             7 .. 23
  9  hour               1,404 bytes             7 .. 23
  10  hour               1,404 bytes             7 .. 23
  11  hour               1,269 bytes             7 .. 23
```

**Sorted, each group covers an hour or two; shuffled, every group covers the whole day, 7 to 23.** A
filter on `hour >= 21` can skip the first nine groups of the sorted file, and none of the shuffled
one. The shuffled `hour` chunks are also sixteen times larger, 1,404 bytes against 88, because a run
of identical values compresses to nearly nothing and a jumble of seventeen does not. And both
footers grew to over 9,000 bytes against the 1,576 of lesson 15's single group: the footer lists
every chunk of every group, so twelve groups is a footer twelve times as long.

## What the three layouts read

The same question, the sales after nine at night, of the curated layer with one group a day, then of
the two layouts with twelve:

```
ana@laptop:~/aws$ python3 ask.py "SELECT sum(total_cents) / 100 AS late FROM orders WHERE hour >= 21" | tail -2
read from S3: 4,914,494 bytes in 93 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/groups/:parquet "SELECT sum(total_cents) / 100 AS late FROM t WHERE hour >= 21"
┌─────────────┐
│    late     │
│   double    │
├─────────────┤
│ 16481827.62 │
└─────────────┘

read from S3: 3,154,464 bytes in 126 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/groups-shuffled/:parquet "SELECT sum(total_cents) / 100 AS late FROM t WHERE hour >= 21" | tail -2
read from S3: 7,261,486 bytes in 418 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**3,154,464 bytes sorted, 7,261,486 shuffled, and 4,914,494 for the one group a day.** The sorted
groups won: the reader skipped most of each day's `total_cents`. The shuffled groups lost to the
single group, because they skipped nothing and paid for longer footers and worse compression on the
way. **The statistics are free, and they help only a reader whose filter matches the order the rows
were written in.**

## How big a group should be

PyArrow puts up to about a million rows in a group by default, which is why each of `lake.py`'s
days, some 20,000 to 32,000 rows, is a single group with one range for the whole day. Spark and Hive
aim at groups of about 128 MB. Two thousand rows is far too small for a real lake, and it is used here
only so that one day has enough groups to see. The lesson for a real one is the order rather than the
size: **sort by the column most queries filter on after the partition key**, when the file is
written, which is the job's business, lesson 17's, and costs nothing at query time.
