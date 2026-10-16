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
offers four codecs: `gzip`, `snappy`, `lz4` and `zstd`. Compression can be set in two places. **On
the producer**, `compression.type` (`none` by default) makes the client compress each batch before
sending it, which saves the network as well as the disk. **On the topic**, the setting of the same
name makes the broker store batches in the codec it names, recompressing whatever arrives in another
one. Its default, `producer`, keeps whatever the producer sent, and its word for no compression is
`uncompressed`, not `none`. The measurement here uses the topic setting, because it needs no change
to `tills.py`; the producer setting is what a real pipeline uses, and it was not measured here.

## The same sales, four times

Four topics, one per codec:

```
ubuntu@stream:~/work$ for c in uncompressed gzip lz4 zstd; do kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-$c --partitions 1 --config compression.type=$c; done
Created topic sales-uncompressed.
Created topic sales-gzip.
Created topic sales-lz4.
Created topic sales-zstd.
```

The same hundred thousand sales into each, from the same seed, so the four topics hold identical
messages:

```
ubuntu@stream:~/work$ for c in uncompressed gzip lz4 zstd; do python tills.py --topic sales-$c --count 100000 --rate 0; done
sent 100000 sales to sales-uncompressed, the last one at 13:39:21
sent 100000 sales to sales-gzip, the last one at 13:39:21
sent 100000 sales to sales-lz4, the last one at 13:39:21
sent 100000 sales to sales-zstd, the last one at 13:39:21
```

And the sizes, with the bytes per sale beside each, largest first:

```
ubuntu@stream:~/work$ kafka-log-dirs.sh --bootstrap-server localhost:9092 --describe --topic-list sales-uncompressed,sales-gzip,sales-lz4,sales-zstd | grep '^{' | jq -r '.brokers[0].logDirs[0].partitions[] | "\(.partition)  \(.size)  \(.size / 100000 * 10 | round / 10)"' | sort -k2 -n -r
sales-uncompressed-0  13526579  135.3
sales-lz4-0  3148477  31.5
sales-zstd-0  1687741  16.9
sales-gzip-0  1449945  14.5
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A bar chart of bytes on disk per sale for the same 100 000 sales stored four ways: uncompressed 135.3, lz4 31.5, zstd 16.9, gzip 14.5.\" data-fig=\"l17-codecs\"><text x=\"138\" y=\"42\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uncompressed</text><rect x=\"150\" y=\"30\" width=\"487.08000000000004\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.08\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">135.3</text><text x=\"138\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lz4</text><rect x=\"150\" y=\"68\" width=\"113.4\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"271.4\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">31.5</text><text x=\"138\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">zstd</text><rect x=\"150\" y=\"106\" width=\"60.839999999999996\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"218.84\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">16.9</text><text x=\"138\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">gzip</text><rect x=\"150\" y=\"144\" width=\"52.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.2\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">14.5</text><text x=\"150\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bytes per sale</text></svg>", "caption": "Bytes on disk per sale, measured: the same sales take an eighth of the space with zstd, and a little less with gzip."}
```

Uncompressed, the topic is the same 135.3 bytes a sale as `bytes` in the last section. **`lz4` cuts
it to about a quarter, `zstd` to about an eighth, and `gzip`, at 14.5 bytes, comes out smallest of
the four on these sales**, with `zstd` close behind at 16.9. That order is a fact about this data
and these batches, not a ranking of the codecs: it is the reason to measure on your own messages
before choosing.

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
| `zstd` | a ratio close to `gzip`'s at a far lower processor cost; it has levels |

For a new pipeline the usual choice is `zstd` on the producer, or `lz4` where processor time is the
scarcer resource; `gzip` won on size here and still loses that choice on speed, which this lab did
not measure. **Whatever the choice, it multiplies everything after it**: the disk on every
replica, the network between brokers and to every consumer, and the bill for keeping a week of it.
