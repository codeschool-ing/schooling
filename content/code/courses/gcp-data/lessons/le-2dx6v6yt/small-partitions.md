---
title: Small partitions, and the granularity that is too fine
version: 1
---

**A finer partition prunes more precisely and costs something every query pays.** If one day per
partition is good, one hour per partition looks better: a query about the evening rush would read
sixteen times less. The catch is that each partition is a piece of storage with its own metadata,
and a table cut into thousands of small pieces makes every query that reads many of them do more
work for the same rows. The bill on demand does not show it, since the bytes are the same; the time
does, and so does a limit.

## Three more layouts

**The same orders, written three more ways**, so this section and the next can compare them. Save
this as `~/gcp/relayout.py`:

`relayout.py`:

```python
import duckdb

con = duckdb.connect()
con.sql("CREATE VIEW orders AS SELECT * FROM read_parquet("
        "'warehouse/orders/**/*.parquet', hive_partitioning = true)")

con.sql("""COPY (SELECT *, hour(created_at AT TIME ZONE 'America/Sao_Paulo') AS hour
                 FROM orders ORDER BY created_at)
           TO 'warehouse/orders_by_hour' (FORMAT parquet, PARTITION_BY (dt, hour))""")

con.sql("""COPY (SELECT * FROM orders ORDER BY created_at)
           TO 'warehouse/orders_by_time' (FORMAT parquet, PARTITION_BY (dt), ROW_GROUP_SIZE 2048)""")

con.sql("""COPY (SELECT * FROM orders ORDER BY dt, store_id, created_at)
           TO 'warehouse/orders_by_store' (FORMAT parquet, PARTITION_BY (dt), ROW_GROUP_SIZE 2048)""")
print('three layouts written')
```

**`orders_by_hour` is partitioned by day and by hour**, so a day becomes a folder of sixteen folders.
The other two keep one file a day and are for the next section: both cut each file into groups of
2,048 rows, one in the order the orders arrived and one sorted by store. `COPY ... PARTITION_BY`
is DuckDB writing Hive folders itself, the same `dt=` naming as lesson 13. Because each new folder
sits under `warehouse/`, `ask.py` can query it by name with no change:

```
ana@laptop:~/gcp$ time python3 relayout.py
three layouts written

real	0m3.282s
user	0m4.028s
sys	0m0.785s
ana@laptop:~/gcp$ for t in orders orders_by_hour orders_by_time orders_by_store; do echo "$t $(find warehouse/$t -name "*.parquet" | wc -l) files, $(du -sb warehouse/$t | cut -f1) bytes"; done
orders 60 files, 32451790 bytes
orders_by_hour 966 files, 29812350 bytes
orders_by_time 60 files, 28598105 bytes
orders_by_store 60 files, 29304897 bytes
```

**Nearly a thousand files instead of 60** for the hourly layout: sixteen hours a day makes 960
folders, and in a few of them DuckDB's parallel writer left two files instead of one, which is why
your count may differ by a file or two from this one. The bytes barely move; Parquet's overhead per file is small, and the hourly files
compress about as well as the daily ones.

## The same question, sixteen times as many files

**A question that reads everything opens every file**, and that is where small partitions cost.
The sum per district reads the whole table either way, so the work in rows is identical. DuckDB times
both with `EXPLAIN ANALYZE`, which runs the query and reports how long it took:

```
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN ANALYZE SELECT district, sum(total_cents) FROM orders GROUP BY district" | grep 'Total Time'
││              Total Time: 0.0285s             ││
ana@laptop:~/gcp$ python3 ask.py "EXPLAIN ANALYZE SELECT district, sum(total_cents) FROM orders_by_hour GROUP BY district" | grep 'Total Time'
││              Total Time: 0.164s              ││
```

**The hourly layout took several times as long for the same rows.** Each file has to be found,
opened and its footer read before its rows can be, and nearly a thousand of those cost more than 60. These are
DuckDB's times on a laptop and say nothing about BigQuery's, but the reason behind them, a fixed
cost for every piece, holds there as well: Google's documentation on partitioned tables advises
against partitions that each hold little data, and suggests clustering instead when partitioning
would make them small. It also sets a maximum number of partitions a table may have, listed with
BigQuery's quotas and limits, and an hourly table reaches it far sooner than a daily one.

## Choosing the granularity

**Partition by the coarsest unit that the common filters still prune well.** At Quitanda nearly
every report asks about days, weeks or months, so a day per partition prunes them all, and the
evening-rush question is better served by clustering on the hour than by partitioning on it. An hour
per partition suits a table that receives a great deal every hour and is queried by the hour, such as
the app's click stream that lesson 19 brings in. A month per partition suits a table that is small
per day, where daily partitions would each hold little; a year suits almost nothing.

**Partition expiration works at the same granularity**, which is one more reason to match it to how
the data ages. With daily partitions and `partition_expiration_days = 1095`, each day leaves the table
on the day it turns three years old. With monthly partitions, a whole month leaves at once, on the
day its first day turns three.
