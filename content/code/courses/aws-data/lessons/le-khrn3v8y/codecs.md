---
title: Codecs, and what a compressed byte costs
version: 1
---

**Athena bills the bytes it reads from S3, and a compressed file is read compressed.** So a codec
that halves the stored size halves the bill for every query that reads the file, which makes the
codec the cheapest of the decisions: one argument to the writer. What it costs is time on the
processors that write and read, which this lesson does not measure, and for one codec the ability to
split a file.

The question from lesson 15, October's sales by payment, asked of five layouts. The answer is the same
four rows every time, so only the gzipped CSV, the first one, is shown whole:

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/csv-gzip/:csv "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC"
┌──────────────┬────────┬─────────────┐
│   payment    │ orders │    reais    │
│   varchar    │ int64  │   double    │
├──────────────┼────────┼─────────────┤
│ pix          │ 348030 │ 41382125.37 │
│ credit       │ 249543 │ 29611096.91 │
│ debit        │  97614 │ 11585221.55 │
│ meal-voucher │  60324 │  7158978.69 │
└──────────────┴────────┴─────────────┘

read from S3: 8,421,323 bytes in 206 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/parquet-none/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 6,481,669 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/orders/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 5,102,048 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/parquet-zstd/:parquet "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 4,280,951 bytes in 62 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

```
ana@laptop:~/aws$ python3 ask.py -t t=quitanda-curated-prod/layouts/orc-zstd/:orc "SELECT payment, count(*) AS orders, sum(total_cents) / 100 AS reais FROM t GROUP BY payment ORDER BY reais DESC" | tail -2
read from S3: 2,820,788 bytes in 155 GET requests to 31 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

## Reading the five numbers

**The gzipped CSV read all 8,421,323 of its bytes**, a fifth of the plain CSV's 40,641,097, and still
every column of every row. Compression made the read smaller and did nothing to make it selective:
the engine decompressed each file from its first byte to find two fields per line. It also has a
cost that does not show here. **A gzip file cannot be split**: decompressing starts at the beginning,
so one reader takes the whole file. On a month of 1 MB files that does not matter; on one 10 GB
export it means one worker of a job reads it while the others wait.

**The three Parquet numbers fall with the codec**: 6,481,669 bytes with none, 5,102,048 with Snappy,
4,280,951 with zstd. They fall less than the file sizes did, from 24,667,617 to 7,433,857. The two columns this question reads were already small: `payment` is a dictionary of four values
whatever the codec, and most of what compression removes is in `order_id` and `customer_id`, which
the question never touches. **A codec saves in proportion to what the question reads, not to what
the file holds.**

**ORC with zstd read 2,820,788 bytes, the least of all**, in 155 requests where Parquet made 62. The
ORC reader fetches a file's tail in more and smaller pieces than PyArrow's Parquet reader, and that
difference is the engine's rather than the format's: Athena's engine reads both formats with readers
of its own.

## Which codec

Snappy is the default of PyArrow and Spark for Parquet, fast to write and to read, and it is never a
mistake. zstd is smaller at the cost of more work when writing. For a lake read many times more often than it is written, a smaller file paid for once and read thousands of times is usually the better trade. Gzip and plain CSV belong in the raw layer, where files arrive the way the source sends
them, and nowhere a dashboard reads.
