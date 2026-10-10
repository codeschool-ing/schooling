---
title: What a partition looks like on disk
version: 1
---

**A partition is a directory, and the log in it is a row of files called segments.** Each segment
holds a run of consecutive offsets, and only the last one, the **active segment**, is ever written
to. When it reaches its size or age limit, Kafka closes it and opens a new one. Everything else in
this lesson, from finding an offset quickly to deleting old data, works a segment at a time.

The directory is named after the topic and the partition. Partition 1 of `sales`, which has most of
the thousand sales:

```
ubuntu@stream:~/work$ ls -l ~/kafka-data/node1/log/sales-1
```

One segment so far, so three files share one name, and the name is the **base offset** of the
segment, the first offset in it, padded to twenty digits:

- **`.log`** holds the messages themselves, one after another, as they arrived. LOGSIZE
- **`.index`** maps offsets to byte positions in the `.log`, so that a reader asking for offset
  500 does not have to read from the start, which was `minilog.py`'s problem in lesson 2. It shows
  10 485 760 bytes because Kafka gives the active segment's index its full size in advance; a
  closed segment's index is trimmed to what it holds, as the retention section shows.
- **`.timeindex`** maps timestamps to offsets, for a reader that asks *from 10 o'clock onwards*,
  which lesson 4 does.
- `partition.metadata` holds the topic's id, and `leader-epoch-checkpoint` records which leader
  wrote which range of offsets, which matters once there are replicas (lesson 5).

## Inside the .log

`kafka-dump-log.sh` reads a segment and prints it. With `--print-data-log` it shows each message's
key and value as well:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-1/00000000000000000000.log --print-data-log | head -5
```

DUMP-PROSE

## Inside the .index

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-1/00000000000000000000.index
```

INDEX-PROSE
