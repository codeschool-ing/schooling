---
title: The checkpoint, and what a restart reads
version: 1
---

Your consumer in lesson 4 kept its place in Kafka, by committing offsets for its consumer group.
**Spark does not. It keeps its place in the checkpoint directory**, together with the open windows,
and a query that starts again reads that directory to know what it already did. Lose the directory
and the query starts from nothing; keep it and a crash costs one batch at most.

Look inside the one the update run wrote:

```
ubuntu@stream:~/work$ ls ~/spark/ckpt/update ~/spark/ckpt/update/state/0
```

| entry | what is in it |
|---|---|
| `metadata` | the query's id, written once, so a restart knows it is the same query |
| `offsets` | one file per batch, written **before** the batch runs: which offsets it will read |
| `commits` | one file per batch, written **after** the batch's output reached the sink |
| `sources` | what the Kafka source found when the query first started |
| `state` | the open windows, one directory per shuffle partition, two here |

The two logs are the heart of it. A batch is planned, its plan is written to `offsets`, it runs,
its rows are handed to the sink, and only then is it written to `commits`. **A batch in `offsets`
with no matching file in `commits` is a batch that did not finish**, and the first thing a restart
does is run it again, with exactly the offsets it had, not with whatever has arrived since.

@@fig:l12-checkpoint@@

The plan for the last batch is a small text file. Its second line holds the watermark and the time
the batch ran, and its third line the offsets, per partition, that the batch read up to:

```
ubuntu@stream:~/work$ tail -1 ~/spark/ckpt/update/offsets/5
```

Partition 0 up to 41, partition 1 up to 159, and partition 2, which no shop's key lands in, at 0.
That is every one of the 200 sales.

## Starting it again

Run the same query, with the same checkpoint, on a topic that has not changed:

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

**It printed nothing.** `startingOffsets` said `earliest`, and Spark ignored it: that option is
only read the first time a query runs, and after that the checkpoint wins. There was nothing past
offset 159 to read, so no batch ran.

Now two more sales arrive, typed into Kafka's console producer instead of coming from the till: one
from Recife at 09:38, which belongs in the 09:35 window, and one from Natal at 09:21, which is
seventeen minutes behind the latest sale Spark has seen:

```
ubuntu@stream:~/work$ printf '%s\n' 'recife|{"sale": "rec-000201", "shop": "recife", "book": "bk-03", "qty": 1, "cents": 2990, "at": "2026-03-02T09:38:00-03:00"}' 'natal|{"sale": "nat-000202", "shop": "natal", "book": "bk-01", "qty": 1, "cents": 3990, "at": "2026-03-02T09:21:00-03:00"}' | kafka-console-producer.sh --bootstrap-server localhost:9092 --topic sales --reader-property parse.key=true --reader-property 'key.separator=|'
```

`parse.key=true` and the separator make the producer split each line into a key and a value, as
`tills.py` does. Run the query a third time:

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

The numbering carries on from batch 6, because the checkpoint remembers batches 0 to 5. **The 09:35
window went from 13 sales to 14**, which is only possible because its count of 13 came back from
the `state` directory: the process that counted those 13 had ended minutes before.

And the sale from Natal is in no output at all. The watermark was 09:34:41 when this run started,
the 09:20 window ends at 09:25, and Spark had already forgotten it. **A sale behind the watermark
is dropped without a word**, which is exactly what lesson 11 said a watermark buys and costs.

## No consumer group

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

The list is empty. Spark read the topic three times and Kafka holds no record of where it got to,
because Spark assigns itself the partitions directly and never commits. **Tools that measure lag
from a consumer group, which lesson 16 uses, see nothing of a Spark query**; Spark reports its own
progress instead, through the query's status and the web page on port 4040.

Two consequences are worth carrying away. A checkpoint belongs to one query: pointing a changed
query at an old checkpoint is a way to restore state that no longer fits, and Spark's guide lists
which changes it accepts. And a checkpoint is the only copy of the query's position and state, so
**on a real cluster it lives on storage that outlives the machine**, such as HDFS or an object
store, never on the local disk of a node that can disappear.
