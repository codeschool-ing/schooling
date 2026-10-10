---
title: Compaction, the latest value for every key
version: 1
---

**A compacted topic keeps, for every key, at least the last message written with that key, and is
allowed to throw away the older ones.** Retention by time or size forgets the past wholesale;
compaction forgets only what has been overwritten. It is lesson 2's table made on disk: a stream of
changes, folded down to the latest value per key, and still readable as a log.

That suits a topic whose messages are **state rather than events**: the current stock of each book,
the current address of each customer. Nobody needs the stock as it was on Tuesday, but a new reader
needs every book's current stock, and a compacted topic gives it that by reading from offset 0. It
does not suit `sales`, where every message is a separate fact and the old ones are not superseded by
the new.

## Watching it work

The cleaner, the broker thread that compacts, is cautious by default: it leaves a log alone until
half of it is overwritten values, and it never touches the active segment. So this topic closes
segments after five seconds and gets cleaned as soon as 1% of it is dirty, which a real topic would
not do:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock --partitions 1 --config cleanup.policy=compact --config segment.ms=5000 --config min.cleanable.dirty.ratio=0.01
```

STOCK-PROSE

```
ubuntu@stream:~/work$ python keys.py stock bk-04=9
```

ROLL-PROSE

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock --from-beginning --max-messages 4 --formatter-property print.offset=true --formatter-property print.key=true
```

AFTER-PROSE

@@fig:l3-compaction@@

## Tombstones

A message with a key and no value is a **tombstone**: it says *this key is deleted*. Compaction
keeps the tombstone itself for `delete.retention.ms`, a day by default, so that a reader who is
part way through the log sees the deletion instead of missing it, and then removes the tombstone
too. After that, the key is simply absent, as if it had never been written.

Two things follow that people get wrong. **Compaction is not immediate**: until the cleaner runs, a
reader from offset 0 sees every old value, so a reader of a compacted topic still has to fold, and
take the last value per key as `balance.py` did. And **compaction keeps offsets**: the surviving
messages keep the offsets they were written at, so a compacted partition has holes in its offsets,
and a reader must not assume offset *n* + 1 follows *n*. Lesson 14 meets compacted topics again,
where a database's rows arrive as messages keyed by primary key and a deleted row becomes a
tombstone.
