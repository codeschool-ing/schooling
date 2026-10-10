---
title: Compression, measured four ways
version: 1
---

**JSON sales compress very well, because they repeat themselves.** Every sale spells out `"shop"`,
`"book"`, `"qty"`, `"cents"` and `"at"`; five shop names and eight book codes cover every value; each
timestamp shares most of its characters with the one before. A compressor working on a batch
of hundreds of sales finds those repetitions and stores them once.

Kafka compresses **a batch at a time**, never a single message, so the gain depends on how many
messages share a batch, which is one more reason the producer's batching (lesson 4) matters. It
offers four codecs besides `none`: `gzip`, `snappy`, `lz4` and `zstd`. Compression can be set in two
places. **On the producer**, `compression.type` makes the client compress each batch before sending
it, which saves the network as well as the disk. **On the topic**, the same name as a topic setting
makes the broker store batches in that codec, recompressing whatever arrives in another one. The
measurement here uses the topic setting, because it needs no change to `tills.py`; the producer
setting is what a real pipeline uses, and it was not measured here.

## The same sales, four times

Four topics, one per codec:

```
ubuntu@stream:~/work$ for c in uncompressed gzip lz4 zstd; do kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-$c --partitions 1 --config compression.type=$c; done
```

The same hundred thousand sales into each, from the same seed, so the four topics hold identical
messages:

```
ubuntu@stream:~/work$ for c in uncompressed gzip lz4 zstd; do python tills.py --topic sales-$c --count 100000 --rate 0; done
```

And the sizes, with the bytes per sale beside each, largest first:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list sales-uncompressed,sales-gzip,sales-lz4,sales-zstd | grep '^{' | jq -r '.brokers[0].logDirs[0].partitions[] | "\(.partition)  \(.size)  \(.size / 100000 * 10 | round / 10)"' | sort -k2 -n -r
```

@@fig:l17-codecs@@

## What it costs

Compression is paid for in processor time: by the producer that compresses, and by every consumer
that decompresses, once per group. With the topic setting, the broker pays as well, because it
recompresses every batch on the way in. That cost was not measured here, and it is the half of the
trade a disk bill hides. The codecs differ in where they sit on it:

| codec | where it sits |
|---|---|
| `gzip` | small output, slow to compress; the old default of many tools |
| `snappy` | fast, modest ratio; common in older pipelines |
| `lz4` | very fast to compress and decompress, a moderate ratio |
| `zstd` | the best ratio of the four at a speed close to `lz4`'s; it has levels |

For a new pipeline the usual choice is `zstd` on the producer, or `lz4` where processor time is the
scarcer resource. **Whatever the choice, it multiplies everything after it**: the disk on every
replica, the network between brokers and to every consumer, and the bill for keeping a week of it.
