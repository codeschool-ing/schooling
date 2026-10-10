---
title: A windowed count, in three output modes
version: 1
---

The count lessons 10 and 11 built by hand, sales per five-minute window of event time with a
watermark, is a few lines of Spark. **What takes thought is not the query but the output mode**:
after each batch, which rows of the result table leave for the sink. There are three, and the same
two hundred sales come out of each one differently.

Save this as `~/work/spark_sales.py`. The rest of the lesson runs it with different arguments
rather than editing it:

```schooling-example
@file spark_sales.py
@lang python
--- What it counts, and the four arguments the rest of the lesson changes.
"""spark_sales.py: Ponto Final's sales per five-minute window, counted by Spark.

    python spark_sales.py [--mode M] [--trigger T] [--sink S] [--checkpoint DIR]

--mode is update, append or complete. --trigger is available-now, a number
of seconds, or continuous. --sink is console, kafka or files.
"""
import argparse
import os

from pyspark.sql import SparkSession
from pyspark.sql import functions as F

args = argparse.ArgumentParser()
args.add_argument("--mode", default="update")
args.add_argument("--trigger", default="available-now")
args.add_argument("--sink", default="console")
args.add_argument("--checkpoint", default="~/spark/ckpt/sales")
args = args.parse_args()

--- The session from the last section, with one more line. **`spark.sql.shuffle.partitions` is how many pieces a grouping is split into**, and its default of 200 means 200 small tasks and 200 pieces of state per batch, which on one machine is all overhead.
spark = (SparkSession.builder.appName("spark-sales").master("local[2]")
         .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3")
         .config("spark.sql.session.timeZone", "America/Sao_Paulo")
         .config("spark.sql.shuffle.partitions", "2")
         .config("spark.ui.showConsoleProgress", "false")
         .getOrCreate())
spark.sparkContext.setLogLevel("ERROR")

--- The value is parsed as JSON with a schema written as SQL types, and `at` becomes a timestamp. **`maxOffsetsPerTrigger` caps each batch at 50 records**, so that the two hundred sales already in the topic arrive in four batches and you can watch the count move instead of seeing it all at once.
SALE = "sale STRING, shop STRING, book STRING, qty INT, cents BIGINT, at TIMESTAMP"
sales = (spark.readStream.format("kafka")
         .option("kafka.bootstrap.servers", "localhost:9092")
         .option("subscribe", "sales")
         .option("startingOffsets", "earliest")
         .option("maxOffsetsPerTrigger", 50)
         .load()
         .select(F.from_json(F.col("value").cast("string"), SALE).alias("s"))
         .select("s.*"))

--- The query itself. **`withWatermark` says that a sale more than two minutes older than the latest one seen may be ignored**, which is what lets Spark close a window and forget it. Then a tumbling window of five minutes on `at`, a count, a sum, and the window's start and end printed as shop times.
per_window = (sales.withWatermark("at", "2 minutes")
              .groupBy(F.window("at", "5 minutes"))
              .agg(F.count("*").alias("sales"), F.sum("cents").alias("cents"))
              .select(F.date_format("window.start", "HH:mm").alias("start"),
                      F.date_format("window.end", "HH:mm").alias("end"), "sales", "cents"))

--- Where the rows go. Every sink gets the output mode and a checkpoint directory; section 06 opens the directory, and section 08 is about the Kafka and file sinks, which need the rows in a shape of their own.
if args.sink == "kafka":
    per_window = per_window.select(F.col("start").alias("key"),
                                   F.to_json(F.struct("*")).alias("value"))
out = (per_window.writeStream.outputMode(args.mode)
       .option("checkpointLocation", os.path.expanduser(args.checkpoint)))
if args.sink == "kafka":
    out = (out.format("kafka").option("kafka.bootstrap.servers", "localhost:9092")
           .option("topic", "sales-per-window"))
elif args.sink == "files":
    out = out.format("json").option("path", os.path.expanduser("~/spark/out"))
else:
    out = out.format("console")

--- When batches run, which is section 07. Nothing has happened until `start`, which launches the query in the background and returns; `awaitTermination` keeps the program alive until the query ends.
if args.trigger == "available-now":
    out = out.trigger(availableNow=True)
elif args.trigger == "continuous":
    out = out.trigger(continuous="1 second")
else:
    out = out.trigger(processingTime=f"{args.trigger} seconds")
out.start().awaitTermination()
```

Each run below gets a checkpoint directory of its own. A checkpoint belongs to one query, and
section 06 shows what happens when a query finds an old one.

## Update: the rows that changed

```
ubuntu@stream:~/work$ python spark_sales.py --mode update --checkpoint ~/spark/ckpt/update 2>spark.log
```

**Update mode prints, after each batch, only the windows that batch changed**, with their totals
so far. The 09:05 window shows 18 sales after batch 0 and 28 after batch 1: the same window twice,
and a reader downstream has to replace the first row with the second, not add them.

Batch 0 has a surprise in it: a 09:10 window with one sale, before 09:05 is finished. Spark took
its 50 records from both partitions with data, in proportion to what each held, and partition 0
holds only Caruaru's sales, which are sparser. **Ten records of partition 0 reach further into
the morning than forty of partition 1**, so one batch saw a sale from 09:10 alongside sales from
09:08. Event time across partitions is never in order, which is lesson 9 arriving in a real engine.

Batch 5 read nothing and printed an empty table. Spark ran it anyway because the watermark had
moved at the end of batch 4, and a batch with no data is how it gets a chance to act on that.

## Complete: the whole table, every time

```
ubuntu@stream:~/work$ python spark_sales.py --mode complete --checkpoint ~/spark/ckpt/complete 2>spark.log
```

**Complete mode prints the entire result after every batch**, in no particular order. It is the
easiest to consume, because the latest output is always the whole answer, and the most expensive:
Spark has to keep every window forever, so the watermark is not used to drop anything. Over a
stream that never ends, that state never stops growing, which is why complete mode only makes
sense for a result that stays small, such as a total per shop.

## Append: only what is final

```
ubuntu@stream:~/work$ python spark_sales.py --mode append --checkpoint ~/spark/ckpt/append 2>spark.log
```

**Append mode prints a window once, when the watermark says it can no longer change**, and never
again. Batch 0 printed nothing: the watermark begins at zero, so no window is final yet. At the end
of batch 0 the latest sale seen was from 09:10:12, so the watermark for batch 1 became 09:08:12,
past the end of the 09:00 window, and batch 1 printed it, with its final count of 30.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Append mode over the two hundred sales. Eight five-minute windows from 09:00 to 09:40 lie along a time axis. Below them, the watermark Spark used in each batch: zero in batch 0, then 09:08:12, 09:15:49, 09:24:24, 09:34:33 and 09:34:41. Each window is printed in the first batch whose watermark has passed its end: 09:00 in batch 1, 09:05 and 09:10 in batch 2, 09:15 in batch 3, 09:20 and 09:25 in batch 4. The 09:30 and 09:35 windows are never printed, because the watermark stops at 09:34:41.\" data-fig=\"l12-append\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">windows</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">watermark</text><rect x=\"111.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:00</text><text x=\"145.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 1</text><rect x=\"181.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:05</text><text x=\"215.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 2</text><rect x=\"251.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:10</text><text x=\"285.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 2</text><rect x=\"321.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:15</text><text x=\"355.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 3</text><rect x=\"391.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:20</text><text x=\"425.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 4</text><rect x=\"461.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:25</text><text x=\"495.0\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">batch 4</text><rect x=\"531.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"565.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:30</text><rect x=\"601.0\" y=\"55\" width=\"68\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">09:35</text><text x=\"558.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never printed</text><text x=\"20\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">printed in</text><line x1=\"110.0\" y1=\"140\" x2=\"670.0\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"224.79999999999998\" y1=\"128\" x2=\"224.79999999999998\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"224.79999999999998\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 1</text><text x=\"224.79999999999998\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:08:12</text><line x1=\"331.43333333333334\" y1=\"128\" x2=\"331.43333333333334\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"331.43333333333334\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 2</text><text x=\"331.43333333333334\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:15:49</text><line x1=\"451.59999999999997\" y1=\"128\" x2=\"451.59999999999997\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"451.59999999999997\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 3</text><text x=\"451.59999999999997\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:24:24</text><line x1=\"593.6999999999999\" y1=\"128\" x2=\"593.6999999999999\" y2=\"152\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"593.6999999999999\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">batch 4</text><text x=\"593.6999999999999\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">09:34:33</text><line x1=\"595.5666666666666\" y1=\"128\" x2=\"595.5666666666666\" y2=\"152\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"591.5666666666666\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">batch 5</text><text x=\"591.5666666666666\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">09:34:41</text><circle cx=\"623.5666666666666\" cy=\"140\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"629.5666666666666\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">last sale 09:36:41</text><line x1=\"623.5666666666666\" y1=\"146\" x2=\"623.5666666666666\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\" stroke-dasharray=\"2 2\"></line></svg>", "caption": "A window leaves in append mode when the watermark passes its end; the last two wait for a sale that never comes."}
```

Count the windows: six were printed, and the data has eight. **The 09:30 and 09:35 windows were
never printed**, and they are not lost. The last sale is from 09:36:41, so the watermark stopped at
09:34:41, and the 09:30 window ends at 09:35. Both windows are still in Spark's state, waiting for
a sale late enough to push the watermark past them. In a shop that sale comes a few seconds later;
in a topic that has stopped receiving sales, it never comes.

| mode | after each batch | state kept | watermark needed |
|---|---|---|---|
| update | the windows that changed, totals so far | until the watermark passes | to forget windows |
| complete | every window | everything, forever | no |
| append | windows that are final, once each | until the watermark passes | yes |

Which to use is decided by the sink and by who reads it. A table that can be updated in place, or a
compacted Kafka topic keyed by window, takes update mode. A file or anything else that can only be
added to takes append mode, at the price of the watermark's delay. Section 08 tries both.
