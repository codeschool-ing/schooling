---
title: Partitioning, and the cost of small files
version: 1
---

**A partition key is chosen by the queries, and limited by the files it leaves.** The key should be
the column most questions filter on, because a filter on the key opens only the matching prefixes,
which is what lesson 15 measured. But every distinct value of the key is at least one file, and a file
has a cost of its own whatever it holds: a request to open it, a footer to read, a row in the catalog.
A key with too many values buys selectivity with files too small to be worth opening.

Three candidates in Quitanda's orders, and how many values each has:

```
ana@laptop:~/aws$ python3 ask.py "SELECT count(DISTINCT dt) AS days, count(DISTINCT neighbourhood) AS neighbourhoods, count(DISTINCT customer_id) AS customers FROM orders"
┌───────┬────────────────┬───────────┐
│ days  │ neighbourhoods │ customers │
│ int64 │     int64      │   int64   │
├───────┼────────────────┼───────────┤
│    31 │             16 │     39979 │
└───────┴────────────────┴───────────┘

read from S3: 5,880,348 bytes in 93 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Two trees of prefixes under the orders table. On the left, partitioned by dt: 31 prefixes such as dt=2026-10-01, each holding one file of about 400 KB, and a question about one day opens one file. On the right, partitioned by customer_id: 39,979 prefixes such as customer_id=c-1, each holding one file with 318 bytes of data on average, and a question about one day opens all 39,979 files.\" data-fig=\"l19-partitions\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">partitioned by dt</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders/</text><line x1=\"30\" y1=\"46\" x2=\"30\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"30\" y1=\"74\" x2=\"44\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"44\" y=\"64\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt=2026-10-01/orders.parquet</text><line x1=\"30\" y1=\"46\" x2=\"30\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"30\" y1=\"102\" x2=\"44\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"44\" y=\"92\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt=2026-10-02/orders.parquet</text><line x1=\"30\" y1=\"46\" x2=\"30\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"30\" y1=\"158\" x2=\"44\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"44\" y=\"148\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">dt=2026-10-31/orders.parquet</text><text x=\"52\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… 31 days</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">31 prefixes, one file each</text><text x=\"20\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">about 400 KB a file</text><text x=\"20\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a question about one day opens 1 file</text><text x=\"370\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">partitioned by customer_id</text><text x=\"370\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders/</text><line x1=\"380\" y1=\"46\" x2=\"380\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"74\" x2=\"394\" y2=\"74\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"394\" y=\"64\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"402\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">customer_id=c-1/orders.parquet</text><line x1=\"380\" y1=\"46\" x2=\"380\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"102\" x2=\"394\" y2=\"102\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"394\" y=\"92\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"402\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">customer_id=c-2/orders.parquet</text><line x1=\"380\" y1=\"46\" x2=\"380\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"158\" x2=\"394\" y2=\"158\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><rect x=\"394\" y=\"148\" width=\"300\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"402\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">customer_id=c-17/orders.parquet</text><text x=\"402\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">… 39,979 customers</text><text x=\"370\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">39,979 prefixes, one file each</text><text x=\"370\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">318 bytes of data a file</text><text x=\"370\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a question about one day opens 39,979 files</text></svg>", "caption": "The same month under two partition keys. By day, a few files worth opening; by customer, tens of thousands of files each smaller than its own footer."}
```

**31 days, 16 neighbourhoods, 39,979 customers.** By `dt` each partition is a day of about 400 KB
in one file, and every question with a date in it, which is most of them, opens only its days. By
`neighbourhood`, 16 partitions of a month each, and a question about one neighbourhood skips the
other 15, but a question about yesterday opens all 16. By `customer_id`, one customer's history is a
single prefix, and the month is 39,979 of them: 12,703,975 bytes over 39,979 files is 318 bytes of data
a file, less than a Parquet footer, and a question about October's sales opens every one.

## Small files, measured

`customer_id` was not written as a layout, because 39,979 objects would take longer to write than the
rest of this lesson. The `small-files` layout shows the same failure at a size that can be run: each
day cut into 96 files, which is what a writer that flushes every quarter of an hour leaves behind.
The question about October's sales, then a question about one day:

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/small-files/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 27,000,299 bytes in 5952 GET requests to 2976 objects
Athena would bill 26 MB (whole MB, 10 MB minimum): 0.000223 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/small-files/:parquet "SELECT count(*) AS orders FROM t WHERE dt = '2026-10-15' AND payment = 'pix'" | tail -2
read from S3: 714,177 bytes in 192 GET requests to 96 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py "SELECT count(*) AS orders FROM orders WHERE dt = '2026-10-15' AND payment = 'pix'"
┌────────┐
│ orders │
│ int64  │
├────────┤
│  10885 │
└────────┘

read from S3: 71,697 bytes in 2 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**The month read 27,000,299 bytes in 5,952 requests, more bytes than the 22,068,273 the layout
holds.** Each file is under 64 KiB, so PyArrow's first read of its tail, the footer read lesson 15
found, fetched the whole file, and the column chunks were then fetched again. The same question of
one file a day read 5,102,048 bytes in 62 requests. One day was 714,177 bytes in 192 requests against
71,697 in 2, for the same 10,885 orders. **Small files undo the column format**: past a point, the
part of the bill that pays for opening files is larger than the part that pays for data.

## What the requests cost

Athena's reads are GET requests against your buckets, billed to your account like anybody else's:

```
ana@laptop:~/aws$ python3 prices.py s3 | grep -E 'GET and|PUT'
  Standard: PUT, COPY, POST, LIST                       0.00700  per 1,000
  Standard: GET and the rest                            0.00056  per 1,000
ana@laptop:~/aws$ python3 prices.py athena | tail -1
  SQL queries, per TB scanned                           9.00000  TB
```

At 0.00056 dollars per thousand GETs, the month question costs 5,952 × 0.00056 / 1,000 = 0.0033
dollars in requests on the small files, and 0.000035 on one file a day. The dashboard of lesson 15,
asking every ten minutes, asks 4,464 times in October: **14.88 dollars of GET requests against 0.15**,
before Athena's own bill for the bytes. The listing is billed too, at the higher `LIST` price, a
request per thousand keys.

AWS's guidance for Athena is files of at least about 128 MB, which a lake as small as this one never
reaches and a lake of Quitanda's size in a few years does. The cure for small files is a job that
rewrites each partition into fewer, larger files after it closes, called compaction; lesson 17's
`etl.py` is one, since it writes each day as one file whatever arrived. The cure for a key with too
many values is a coarser key, `dt` and not `customer_id`, with the fine column sorted inside the files
for the statistics of the previous section to use.
