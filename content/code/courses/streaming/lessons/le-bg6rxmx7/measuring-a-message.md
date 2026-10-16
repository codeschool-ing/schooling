---
title: What one sale weighs on disk
version: 1
---

**The size of a message is not the size of its JSON.** A broker stores messages in batches, and
each record carries its key, an offset, a timestamp and a few bytes of framing; each batch carries a
header of its own; and beside the log file sit two index files. Guessing from the payload gets the
order of magnitude right and the bill wrong, so measure it: write a known number of sales into an
empty topic and divide the size Kafka reports by the count.

## A hundred thousand sales

A topic of one partition, so the whole topic is one directory, and a hundred thousand sales from the
tills of lesson 1, sent as fast as Kafka takes them:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic bytes --partitions 1
Created topic bytes.
ubuntu@stream:~/work$ python tills.py --topic bytes --count 100000 --rate 0
sent 100000 sales to bytes, the last one at 13:39:21
```

One sale, as the consumer prints it, counted in bytes by `wc -c` (the count includes the newline
at the end of the line):

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic bytes --from-beginning --max-messages 1 2>/dev/null | wc -c
123
```

## What the broker says

`kafka-log-dirs.sh --describe` asks every broker how much disk each partition uses, and answers in
one line of JSON after two lines about what it is doing:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list bytes
Querying brokers for log directories information
Received log directory information from brokers 1
{"brokers":[{"broker":1,"logDirs":[{"partitions":[{"partition":"bytes-0","size":13526603,"offsetLag":0,"isFuture":false}],"error":null,"logDir":"/home/ubuntu/kafka-data/node1/log"}]}],"version":1}
```

`size` is the bytes of the partition's log segments, 13 526 603 here, and `offsetLag` is how far a replica is behind
its leader, which on one node is always zero. `jq` takes the size out and divides it by the number
of sales:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list bytes | grep '^{' | jq '.brokers[0].logDirs[0].partitions[0].size / 100000'
135.26603
```

**That is the number to use: about 135 bytes on disk per sale, with no compression.** The first
sale is 122 bytes of JSON plus the newline `wc` counted; the rest is the key, `natal` or
`joao-pessoa`, and the record's and the batch's own fields. And it is still a single copy: the
replication factor multiplies it later.

## The directory itself

The same partition, seen as files:

```
ubuntu@stream:~/work$ ls -l ~/kafka-data/node1/log/bytes-0
total 13228
-rw-r--r-- 1 ubuntu ubuntu 10485760 Oct 10 17:11 00000000000000000000.index
-rw-r--r-- 1 ubuntu ubuntu 13526603 Oct 10 17:11 00000000000000000000.log
-rw-r--r-- 1 ubuntu ubuntu 10485756 Oct 10 17:11 00000000000000000000.timeindex
-rw-r--r-- 1 ubuntu ubuntu        8 Oct 10 17:11 leader-epoch-checkpoint
-rw-r--r-- 1 ubuntu ubuntu       43 Oct 10 17:11 partition.metadata
```

The `.log` file is the segment, the bytes `kafka-log-dirs.sh` counted. `.index` and `.timeindex` map
offsets and timestamps to positions in it, which is how lesson 16's reset by datetime found its
offsets. They are created at their full preallocated size, the 10 485 760 bytes `ls` shows, and
trimmed when the segment closes, so their size on a live segment says little. `kafka-log-dirs.sh`
does not count them. Lesson 3 opened these files with `kafka-dump-log.sh`; here the point is only
that **the `size` to multiply is the `.log` file's**, which is exactly what the tool reported.

Two cautions before the number goes into arithmetic. **It depends on the batch**: the tills sent as
fast as they could, so the producer packed many sales per batch, and a producer sending one sale every
few seconds pays a batch header per sale. And **it depends on the message**: add a field to the sale
and the number moves. Measure again when the message changes, which on a real platform means when
its schema does (lesson 6).
