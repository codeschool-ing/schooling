---
title: Bookmarks, and the export that arrives twice
version: 1
---

**A bookmark is what a job remembers between runs: which input it has already done.** Without one,
every night reads the whole raw layer again, which is right for a month and wrong for three years.
With one, the night reads what arrived since the last run that finished, and the bill follows the
new data instead of the history.

## What etl.py remembers

Run it a second time, with nothing new in the raw layer:

```
ana@laptop:~/aws$ python3 etl.py
31 raw files, none of them new: nothing to do
```

**Nothing to do, and nothing read but a listing.** The bookmark held the 31 keys of the first run,
and every key the listing found was in it. That is the whole mechanism in this program: a list of
keys, written to S3 at the end of a run, and read at the start of the next.

## What Glue remembers

Glue's bookmark is the same idea kept by the service, and three details of it decide how a job has
to be written. This part is AWS's documented behaviour; moto does not keep bookmarks at all:

```
ana@laptop:~/aws$ aws glue get-job-bookmark --job-name orders-etl

aws: [ERROR]: An error occurred (500) when calling the GetJobBookmark operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**moto answers with an internal error page, a 500**, because the operation is not implemented. On
AWS that call returns the job's bookmark: for an S3 source, the objects already processed, judged by
their last-modified time. Each read that takes part needs a `transformation_ctx`, the name the
script's `from_catalog` and `getSink` were given, because that name is the key the state is kept
under. **The bookmark moves only at `job.commit()`**, so a run that fails halfway leaves it where it
was and the next run reads the same files again, which makes it essential that reading the same
files twice does no harm. And a bookmark can be reset, to reprocess everything, or paused, to run
once without moving it.

## The export that arrives twice

Now the case from the script's last paragraph. The shop resends the first 500 orders of 15 October
in a second file, the night after:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/orders.csv day15.csv --only-show-errors && head -501 day15.csv > resent.csv
ana@laptop:~/aws$ aws s3 cp resent.csv s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/orders-resent.csv --only-show-errors
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders/dt=2026-10-15/
2026-10-16 13:39:34      26494 orders-resent.csv
2026-10-16 13:39:27    1279794 orders.csv
ana@laptop:~/aws$ python3 etl.py
1 new raw file in 1 day
  2026-10-15: 24,281 rows in 2 files, 500 of them duplicates
  24,281 rows read, 23,781 kept, 401,803 bytes of Parquet written
  0 partitions added to quitanda.orders, 1 already there
```

**One new file, one day rewritten, 500 duplicates dropped.** The bookmark handed the program only
`orders-resent.csv`, and the program read both of 15 October's files anyway, because what it replaces
is the day. The raw layer and the curated layer now disagree, and they should:

```
ana@laptop:~/aws$ python3 ask.py "SELECT count(*) AS orders, count(DISTINCT order_id) AS ids FROM orders_csv WHERE dt = '2026-10-15'"
┌────────┬───────┐
│ orders │  ids  │
│ int64  │ int64 │
├────────┼───────┤
│  24281 │ 23781 │
└────────┴───────┘

read from S3: 1,306,288 bytes in 6 GET requests to 2 objects
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
ana@laptop:~/aws$ python3 ask.py "SELECT count(*) AS orders, count(DISTINCT order_id) AS ids FROM orders WHERE dt = '2026-10-15'"
┌────────┬───────┐
│ orders │  ids  │
│ int64  │ int64 │
├────────┼───────┤
│  23781 │ 23781 │
└────────┴───────┘

read from S3: 227,684 bytes in 2 GET requests to 1 object
Athena would bill 10 MB (whole MB, 10 MB minimum): 0.000086 USD at 9.00 USD per TB
```

**24,281 rows in the raw layer for 23,781 orders, and 23,781 of each in the curated one.** A job that
had added the new file's rows to the day, as the Glue script would, would show 24,281 and 23,781
there as well, and every sum of that day would be 500 orders too high. The bookmark file itself now
holds the new key beside the other 31:

```
ana@laptop:~/aws$ aws s3 cp s3://quitanda-glue-prod/bookmarks/orders-etl.json bookmark.json --only-show-errors
ana@laptop:~/aws$ jq length bookmark.json && jq -r '.[] | select(contains("resent"))' bookmark.json
32
quitanda-raw-prod/raw/orders/dt=2026-10-15/orders-resent.csv
```

One difference from Glue's bookmark is worth naming, because it is a failure this program has and
Glue's does not. **`etl.py` remembers keys, so a file rewritten under the same key is never read
again**; Glue compares the last-modified time, and would read it. An export that corrects a day by
overwriting its file is invisible to `etl.py`, and the fix is to remember each key's ETag, the
fingerprint lesson 1 met, beside its name.
