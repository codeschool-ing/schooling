---
title: Sinks, and which of them make it exactly-once
version: 1
---

The console has been the sink all lesson because it is easy to read, and it is the one sink nobody
runs in production: it keeps nothing, and a batch that runs twice is simply printed twice. **Where
the results go decides two things the query cannot decide alone**: which output modes are possible,
and whether a batch replayed after a crash, the one in section 06's figure, does harm.

Spark's own word for it is that the engine is exactly-once **end to end only when the source can be
replayed and the sink is idempotent**. Kafka is a source that can be replayed: the checkpoint names
the offsets, and reading them again gives the same records. The sink is the half that varies.

| sink | output modes | a batch written twice |
|---|---|---|
| console, memory | all three | printed or stored twice; for testing only |
| files (JSON, Parquet, CSV…) | append only | ignored: a log of finished batches decides what readers see |
| Kafka | append, update | written twice; at-least-once |
| `foreachBatch` | all three | whatever your function does with the batch id it is given |

## Kafka

The topic now holds the hundred sales from section 07. Send the counts to a Kafka topic instead of
the screen, in update mode, with the window's start as the key:

```
ubuntu@stream:~/work$ python spark_sales.py --sink kafka --checkpoint ~/spark/ckpt/kafka 2>spark.log
```

Nothing appeared on the screen; the rows went to `sales-per-window`, which Kafka made on first
use. Read it:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-per-window --from-beginning --formatter-property print.key=true --max-messages 5
```

The `09:05` key appears twice, 20 sales and then 28, because update mode sends a window each time
it changes. **For whoever reads this topic, the last record for a key is the truth**, which is what
a compacted topic keeps (lesson 3). And if Spark crashed after writing a batch and before
committing it, the batch would run again and the same records would be written a second time.
Because each record carries the whole count rather than an increment, a duplicate is harmless to a
reader that keeps the last value per key, and harmful to one that adds them up. That is the
idempotent write of lesson 8, decided by the shape of the record.

## Files

Files are the opposite case. Ask for them in update mode and the query is refused at once:

```
ubuntu@stream:~/work$ python spark_sales.py --sink files --checkpoint ~/spark/ckpt/files 2>spark.log; tail -1 spark.log
```

A file, once written, cannot be updated, so only append mode is allowed:

```
ubuntu@stream:~/work$ python spark_sales.py --sink files --mode append --checkpoint ~/spark/ckpt/files-append 2>spark.log
```

```
ubuntu@stream:~/work$ ls ~/spark/out ~/spark/out/_spark_metadata
```

Each batch wrote one file per shuffle partition, some of them empty, with a random name. **The
`_spark_metadata` directory is what makes this sink exactly-once**: one entry per finished batch,
naming its files. A batch that crashed half-written leaves files that no entry names, and Spark,
reading the directory back, ignores them; a batch that runs again writes new files and one entry.
So read the directory with Spark, not with `cat`, if exactness matters. With `cat` it is three
windows:

```
ubuntu@stream:~/work$ cat ~/spark/out/part-*.json
```

Three, not four: the watermark stopped at 09:15:12, three minutes before the till's last sale, so
the 09:15 window is still waiting, as the 09:30 and 09:35 windows did in section 05.

## And the rest

`foreachBatch` hands your function each micro-batch as an ordinary DataFrame, with its batch
number. It is how a query writes to a database Spark has no sink for, and the batch number is what
makes it safe: store it with the rows, in the same transaction, and a replayed batch can be
recognised and skipped, the offsets-in-the-sink pattern of lesson 8.

Stop here and look back at the whole query: a source that can be replayed, a checkpoint that says
what was read, state that survives a restart, a watermark that drops what is too late, and a sink
that either tolerates a second copy or refuses it. **None of it was written by you, and all of it
was chosen by you**, which is the trade an engine offers. Lesson 13 makes the same count in two
engines that choose differently.
