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
total 124
-rw-r--r-- 1 ubuntu ubuntu 10485760 Oct 10 16:59 00000000000000000000.index
-rw-r--r-- 1 ubuntu ubuntu   106916 Oct 10 16:59 00000000000000000000.log
-rw-r--r-- 1 ubuntu ubuntu 10485756 Oct 10 16:59 00000000000000000000.timeindex
-rw-r--r-- 1 ubuntu ubuntu        8 Oct 10 16:59 leader-epoch-checkpoint
-rw-r--r-- 1 ubuntu ubuntu       43 Oct 10 16:59 partition.metadata
```

One segment so far, so three files share one name, and the name is the **base offset** of the
segment, the first offset in it, padded to twenty digits:

- **`.log`** holds the messages themselves, one after another, as they arrived: 106 916 bytes for 789
  sales, about 135 bytes each.
- **`.index`** maps offsets to byte positions in the `.log`, so that a reader asking for offset
  500 does not have to read from the start, which was `minilog.py`'s problem in lesson 2. It shows
  10 485 760 bytes because Kafka gives the active segment's index its full size in advance, and
  trims it to what it holds when the segment is closed.
- **`.timeindex`** maps timestamps to offsets, for a reader that asks *from 10 o'clock onwards*,
  which lesson 4 does.
- `partition.metadata` holds the topic's id, and `leader-epoch-checkpoint` records which leader
  wrote which range of offsets, which matters once there are replicas (lesson 5).

## Inside the .log

`kafka-dump-log.sh` reads a segment and prints it. With `--print-data-log` it shows each message's
key and value as well:

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-1/00000000000000000000.log --print-data-log | head -5
Dumping /home/ubuntu/kafka-data/node1/log/sales-1/00000000000000000000.log
Log starting offset: 0
baseOffset: 0 lastOffset: 760 count: 761 baseSequence: -1 lastSequence: -1 producerId: -1 producerEpoch: -1 partitionLeaderEpoch: 0 isTransactional: false isControl: false deleteHorizonMs: OptionalLong.empty position: 0 CreateTime: 1791662396759 size: 103095 magic: 2 compresscodec: none crc: 3008869467 isvalid: true
| offset: 0 CreateTime: 1791662396752 keySize: 11 valueSize: 122 sequence: -1 headerKeys: [] key: joao-pessoa payload: {"sale": "joa-000001", "shop": "joao-pessoa", "book": "bk-02", "qty": 1, "cents": 5490, "at": "2026-03-02T09:00:05-03:00"}
| offset: 1 CreateTime: 1791662396752 keySize: 5 valueSize: 117 sequence: -1 headerKeys: [] key: natal payload: {"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}
```

The first two lines name the file and its first offset. The third is not a message: it is a
**batch**, `baseOffset: 0 lastOffset: 760 count: 761`, which says that 761 messages arrived
together, as one batch from the producer, and are stored together. **Kafka stores what the
producer sent, a batch at a time**, without unpacking it, and that is a large part of why it is
fast. The `producerId: -1` and `isTransactional: false` fields are empty here and filled in by
lesson 7's idempotent and transactional producers. Then the messages, each with its offset, its `CreateTime`, its key and its value.
`CreateTime` is the time the producer created the message, in milliseconds since 1970, and not the
sale's own `at`, a difference lesson 9 is about.

## Inside the .index

```
ubuntu@stream:~/work$ kafka-dump-log.sh --files ~/kafka-data/node1/log/sales-1/00000000000000000000.index
Dumping /home/ubuntu/kafka-data/node1/log/sales-1/00000000000000000000.index
offset: 788 position: 103095
```

One entry: the batch that ends at offset 788 starts at byte 103 095 of the `.log`. **The index is
sparse**: Kafka adds an entry only after about 4 096 bytes of messages have gone by
(`index.interval.bytes`), and an entry always points at the start of a batch, so a batch of 761
messages gets none of its own. To find offset 500, a reader takes the nearest entry at or below
it, here none, so the start of the file, and reads forward from there. On
a segment of a gibibyte the entries are thousands, and finding an offset is a binary search in the
index and a short read in the log.
