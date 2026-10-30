---
title: Four meters on every bucket
version: 1
---

**A Cloud Storage bill has four meters, and storage is only one of them.** The other three run when
the data is used: one counts operations, one charges for reading the colder classes, and one counts
the bytes that leave. People price a bucket by its size, multiply by the price per GiB-month, and are
right about the bucket and wrong about the bill, because a bucket that is read a lot is paid for
mostly by the reading.

The four, for a bucket in `southamerica-east1`, from cloud.google.com/storage/pricing, read on
2026-10-30, in USD:

| meter | unit | Standard | Nearline | Coldline | Archive |
|---|---|---|---|---|---|
| storage | GiB-month | 0.035 | 0.020 | 0.007 | 0.003 |
| Class A operations | 1,000 operations | 0.005 | 0.01 | 0.02 | 0.05 |
| Class B operations | 1,000 operations | 0.0004 | 0.001 | 0.01 | 0.05 |
| retrieval | GiB read | 0 | 0.01 | 0.02 | 0.05 |

The fourth meter, **network**, is a table of its own, because its price depends on where the bytes
go rather than on the class they were stored in. Two of its lines matter from the start: data written
into a bucket is free, and data read out of one to the internet costs 0.12 a GiB for the first 10 TiB
of the month. The next two sections are that meter.

**The storage prices are the São Paulo ones; the operation and retrieval prices are not regional.**
The pricing page prints storage per region, and a single table of operations for every bucket that
sits in one region, with another for dual-regions and multi-regions. So the request side of this
lesson's arithmetic is the same wherever the bucket is, and only the storage moves.

## Class A and Class B

**An operation is one request to the API, whatever it carries.** A request that uploads 4 KiB and a
request that uploads 4 GiB are each one Class A operation; a request that reads one byte and a request
that reads a whole file are each one Class B. The pricing page sorts every method of the API into a
class, and the sorting is the part people get wrong:

- **Class A** is everything that writes, and listing: `objects.insert`, `objects.copy`,
  `objects.rewrite`, `objects.compose`, any `patch` or `update`, and **`objects.list` and
  `buckets.list`**.
- **Class B** is reading: any `get`, of the data or of the metadata, and reading a policy.
- **Free** is deleting: `objects.delete`, `buckets.delete`.

**Listing is billed as a write, at twelve and a half times the price of a read.** A program that lists
a prefix to find what to read pays the expensive rate for the listing, and a list returns at most
1,000 names, so listing two million objects is two thousand Class A operations before a single one
of them is read. And the classes get dearer as the storage gets colder: a Class B on Archive costs
0.05 a thousand, 125 times the Standard price, on top of the retrieval fee of 0.05 a GiB. Lesson 2
compares the classes by what they cost to keep; this table is what they cost to touch.

**A failed request is generally not charged.** The page says so in a note: operations answered with
a 307, a 4xx or a 5xx are not billed, with one exception for a website bucket's 404 page. The next
section meets a few hundred of those.

## The size of a request against the size of a gibibyte

The units hide the comparison that matters. A GiB stored for a month at 0.035 buys how many
operations?

```
ana@laptop:~/gcp$ python3 -c 'print(round(0.035 / (0.0004 / 1000)), round(0.035 / (0.005 / 1000)))'
87500 7000
```

**87,500 reads, or 7,000 writes.** When a gibibyte's objects are read more than about 87,000 times in
a month in all, the reading costs more than the keeping. For one file of a GiB that never happens.
For a gibibyte made of objects of 4 KiB, it happens on the first pass:

```
ana@laptop:~/gcp$ python3 -c 'n = 1024 * 1024 // 4; print(n, round(n * 0.0004 / 1000, 4), round(n * 0.005 / 1000, 4))'
262144 0.1049 1.3107
```

**A GiB of 4 KiB objects is 262,144 objects.** Reading each one once costs 0.1049, three times the
month's storage. Writing them cost 1.3107, thirty-seven times it. A request is priced per request
whatever its size, and storage is priced per byte whatever the number of objects. The rest of this
lesson follows from those two facts.

## None of these is metered here

fake-gcs-server counts no operations, charges nothing, and sends no bill. What it does do is log
every request it answers, one line each, and that log is what the next section counts. Every figure
in this lesson is a count multiplied by a price off a page, with the arithmetic shown; on a real
project the same meters arrive as SKUs on the bill, which `gcp-foundations` lesson 13 reads.
