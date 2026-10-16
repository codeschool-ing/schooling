---
title: The same count in Flink SQL
version: 1
---

Flink has a Java API, a Python API and a SQL one. **The SQL is the shortest way to the same
count**: a table over the topic, a table over the output, and one `INSERT` that runs for as long as
the cluster does. The watermark, which lesson 12 declared with `withWatermark`, is part of the
table's definition here, beside its columns.

Save this as `~/work/sales.sql`:

```sql
SET 'execution.checkpointing.interval' = '10 s';
SET 'execution.checkpointing.dir' = 'file:///home/ubuntu/flink-checkpoints';

CREATE TABLE sales (
  sale STRING,
  shop STRING,
  book STRING,
  qty INT,
  cents BIGINT,
  `at` STRING,
  ts AS TO_TIMESTAMP(REPLACE(SUBSTRING(`at`, 1, 19), 'T', ' ')),
  WATERMARK FOR ts AS ts - INTERVAL '2' MINUTE
) WITH (
  'connector' = 'kafka',
  'topic' = 'sales',
  'properties.bootstrap.servers' = 'localhost:9092',
  'properties.group.id' = 'flink-sales',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'json'
);

CREATE TABLE sales_per_window (
  window_start TIMESTAMP(3),
  window_end TIMESTAMP(3),
  sales BIGINT,
  cents BIGINT
) WITH (
  'connector' = 'kafka',
  'topic' = 'flink-sales-per-window',
  'properties.bootstrap.servers' = 'localhost:9092',
  'format' = 'json'
);

INSERT INTO sales_per_window
SELECT window_start, window_end, COUNT(*), SUM(cents)
FROM TABLE(TUMBLE(TABLE sales, DESCRIPTOR(ts), INTERVAL '5' MINUTE))
GROUP BY window_start, window_end;
```

Read it from the bottom. The `INSERT` is the query: a **tumbling window** of five minutes over
`ts`, which lesson 10 drew, grouped and counted. The two `CREATE TABLE` statements do not create
anything in Kafka; they tell Flink how to read a topic as a table and how to write one. `at` is
read as text, and `ts` is a **computed column** made from its first nineteen characters, the shop's
clock time; the `-03:00` at the end is dropped, which is safe because all five shops keep the same
time zone. The
`WATERMARK` line says that `ts` is the event time and that a sale may be up to two minutes late,
the same bound as lesson 12. The two `SET` lines at the top are for section 07.

Submit it. The SQL client prints every statement back as it runs it, and the one line worth keeping
is the job's id, so `grep` keeps that:

```
ubuntu@stream:~/work$ ~/flink/bin/sql-client.sh -f sales.sql 2>/dev/null | grep "Job ID"
Job ID: 28d4b45557a9e6ff9b7385f48a63751f
```

The client has gone, and the job has not: it runs on the cluster now, and will until somebody
stops it. Its results go to `flink-sales-per-window`, so read that:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null
```

## Nothing, and why

**Ten seconds, and not one window**, although Spark printed six from the same sales with the same
watermark. The job is running:

```
ubuntu@stream:~/work$ ~/flink/bin/flink list
Waiting for response...
------------------ Running/Restarting Jobs -------------------
15.10.2026 22:22:56 : 28d4b45557a9e6ff9b7385f48a63751f : insert-into_default_catalog.default_database.sales_per_window (RUNNING)
--------------------------------------------------------------
No scheduled jobs.
```

The reason is lesson 11's idle source. Flink keeps **a watermark per partition** and moves the
job's watermark to the smallest of them, so that no partition's late sales are overtaken. The
`sales` topic has three partitions and partition 2 is empty: no shop's key lands there. A partition
with no records has no watermark at all, so the smallest is nothing, and no window ever closes.
Spark, with one watermark for the whole query, did not wait; Flink waits, which is correct when the
quiet partition is only slow and wrong when it is empty.

The fix is to declare how long a partition may stay quiet before it stops counting. Cancel the job,
with the id `flink list` printed:

```
ubuntu@stream:~/work$ ~/flink/bin/flink cancel 28d4b45557a9e6ff9b7385f48a63751f
Cancelling job 28d4b45557a9e6ff9b7385f48a63751f.
Cancelled job 28d4b45557a9e6ff9b7385f48a63751f.
```

Then add one line to the top of `sales.sql`, saying that a partition silent for five seconds is
idle, and submit it again:

```
ubuntu@stream:~/work$ sed -i "1i SET 'table.exec.source.idle-timeout' = '5 s';" sales.sql
```

```
ubuntu@stream:~/work$ ~/flink/bin/sql-client.sh -f sales.sql 2>/dev/null | grep "Job ID"
Job ID: 1b14e9a9a838ec156cb32b72b8c46fd7
```

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic flink-sales-per-window --from-beginning --timeout-ms 10000 2>/dev/null
{"window_start":"2026-03-02 09:00:00","window_end":"2026-03-02 09:05:00","sales":30,"cents":337340}
{"window_start":"2026-03-02 09:05:00","window_end":"2026-03-02 09:10:00","sales":28,"cents":241740}
{"window_start":"2026-03-02 09:10:00","window_end":"2026-03-02 09:15:00","sales":28,"cents":204680}
{"window_start":"2026-03-02 09:15:00","window_end":"2026-03-02 09:20:00","sales":29,"cents":240130}
{"window_start":"2026-03-02 09:20:00","window_end":"2026-03-02 09:25:00","sales":23,"cents":209180}
{"window_start":"2026-03-02 09:25:00","window_end":"2026-03-02 09:30:00","sales":25,"cents":237180}
```

**Six windows, the same six as lesson 12's append mode**, with the same counts: 30 sales from
09:00, 28 from 09:05, down to 25 from 09:25. The 09:30 and 09:35 windows are held for the same
reason as there: the watermark is two minutes behind the last sale, 09:36:41, and the 09:30 window
ends at 09:35. Flink writes a window once, when it closes, like Spark's append mode, so this output
topic can be read by anything that adds records up.

The two engines agree because the definition is the same: event time from `at`, five-minute windows,
a two-minute bound. What differed was a rule about partitions, and a rule
like that comes with the engine you choose.
