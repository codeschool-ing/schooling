---
title: Offsets, partition by partition
version: 1
---

**An offset is a position in one partition, and it means nothing outside it.** Each partition
counts from 0 on its own, so a topic of three partitions has three offset 0s, and the offsets of
two partitions say nothing about which message was written first. Lesson 2's `minilog.py` had one
counter; a topic has one per partition.

Send a thousand sales with lesson 1's tills, as fast as Kafka takes them, and ask where each
partition has got to:

```
ubuntu@stream:~/work$ python tills.py --count 1000 --rate 0
```

`kafka-get-offsets.sh` prints `topic:partition:offset`, and with no `--time` the offset is the
**log-end offset**: the offset the next message in that partition will get, which is also how many
messages it has ever received, as long as nothing was deleted. Partition 0 has 211 sales and
partition 1 has 789. **Partition 2 has none**, and the last section says why: `tills.py` uses the
Python client's default partitioner, and none of the five shop names hashes to partition 2 under
it. A topic with three partitions is, for these sales, a topic with two, one of them nearly four
times busier than the other. Nothing warns you about that; this command is how you find out.

## The two ends of a partition

The other end is the **earliest** offset, the first one still stored:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic sales --time earliest
```

All three are 0, because nothing has been deleted yet. Between the two ends, every offset holds a
message, and a reader can start at any of them. The section on retention moves the earliest end, and
the one on compaction leaves holes in the middle.

| name | what it is | how to see it |
|---|---|---|
| earliest, or **log start offset** | the first offset still stored | `kafka-get-offsets.sh --time earliest` |
| latest, or **log-end offset** | the offset the next message will get | `kafka-get-offsets.sh` |
| a consumer group's **committed offset** | where that group will resume | lesson 4 |

## Reading from a chosen offset

The console consumer can read one partition from any offset in it:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --partition 1 --offset 5 --max-messages 2 --formatter-property print.offset=true
```

Offsets 5 and 6 of partition 1 are `rec-000006` and `rec-000007`, two Recife sales in the order
the till rang them up. Offset 5 of partition 0 is a different sale altogether: partition 0 holds
only Caruaru's, the one shop that hashed there. **An offset is only an address together with its
partition.** Lesson 4 does the same from Python, and moves a whole consumer group
to an offset or a time.
