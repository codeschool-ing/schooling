---
title: Skipping row groups
version: 1
---

**The footer's smallest and largest values let a reader skip a row group without reading it**, when
the filter rules out every value between the two. Lesson 6 showed why that did nothing for the
silver layer: every day's file is one row group holding every kind and every book, so no filter on
either can rule it out. Lesson 6 also promised to sort the data and measure the difference.

This program writes a copy of the clicks with each day's rows sorted by book, in row groups of 256
KB, and runs the same filter on both: the events of the rarest books, ids from 2,900 up. It uses
lesson 6's `lastscan.py` to report what each scan read. Save it as `~/big/skipping.py`:

```schooling-example
{
  "language": "python",
  "file": "skipping.py",
  "parts": [
    {
      "code": "\"\"\"The same filter on the clicks as they are, and on a copy sorted by book within each day.\"\"\"\nimport time\n\nfrom pyspark.sql import SparkSession\nfrom pyspark.sql import functions as F\n\nfrom lastscan import scans\n\nspark = SparkSession.builder.appName(\"skipping\").getOrCreate()\n\n"
    },
    {
      "code": "(spark.read.parquet(\"data/silver/clicks\")\n .repartition(\"day\").sortWithinPartitions(\"day\", \"book_id\")\n .write.mode(\"overwrite\").option(\"parquet.block.size\", 256 * 1024)\n .partitionBy(\"day\").parquet(\"data/tmp/by-book\"))\n\n\n",
      "note": "**The copy**: each day's rows gathered into one task and sorted by `book_id`, written with row groups of 256 KB instead of the default 128 MB, so that a day's file of about 1 MB holds several. Sorting by `day` first is what `partitionBy(\"day\")` needs anyway, and it keeps Spark from adding a sort of its own that would undo the order by book."
    },
    {
      "code": "def rare(path):\n    return spark.read.parquet(path).where(F.col(\"book_id\") >= 2900).count()\n\n\nfor path in [\"data/silver/clicks\", \"data/tmp/by-book\"]:\n    rare(path)\n    start = time.time()\n    print(f\"{path:20} {rare(path):,} events in {time.time() - start:.1f} s\")\n    scans(spark)\n",
      "note": "**The rare books**: ids from 2,900 up, which lesson 1's cube makes the least viewed."
    }
  ]
}
```

```
ana@lab:~/big$ spark-submit skipping.py
WARNING: Using incubator modules: jdk.incubator.vector
data/silver/clicks   250,517 events in 5.4 s
  365 files of 388.8 MiB, 24,000,000 rows
data/tmp/by-book     250,517 events in 5.1 s
  365 files of 484.4 MiB, 1,013,862 rows
```

**The same 250,517 events, and the scan handed on 1 million rows instead of 24 million.** Both read
all 365 files, because the filter is on a column inside them and only the footers can say what they
hold. But in the sorted copy the footer of each file says that most of its row groups hold books far
below 2,900, and the reader skipped them. The footer of the sorted copy's 1 January:

```
ana@lab:~/big$ ~/pq-env/bin/python footer.py data/tmp/by-book/day=2025-01-01 book_id
65,754 rows in 15 row group(s), 9,594 bytes of footer, written by parquet-mr version 1.16.0 (build 402c3810c372d29603e181771acebfecc71bef61)
column       on disk  decompressed  codec   encodings
                KiB           KiB
event_id       279.4         514.2  SNAPPY  RLE, PLAIN, BIT_PACKED
ts             562.5         875.6  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
visitor_id     448.7         726.8  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
kind            14.4          14.9  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
book_id         24.5          26.2  SNAPPY  RLE, PLAIN, BIT_PACKED
device          17.6          17.5  SNAPPY  PLAIN_DICTIONARY, RLE, BIT_PACKED
row group  0:   4,663 rows, book_id from None to None
row group  1:   4,502 rows, book_id from 1 to 1
row group  2:   4,484 rows, book_id from 1 to 8
row group  3:   4,484 rows, book_id from 8 to 29
row group  4:   4,484 rows, book_id from 29 to 71
row group  5:   4,484 rows, book_id from 71 to 141
row group  6:   4,484 rows, book_id from 141 to 246
row group  7:   4,484 rows, book_id from 246 to 395
row group  8:   4,484 rows, book_id from 395 to 596
row group  9:   4,484 rows, book_id from 596 to 853
row group 10:   4,484 rows, book_id from 853 to 1185
row group 11:   4,484 rows, book_id from 1185 to 1573
row group 12:   4,484 rows, book_id from 1573 to 2055
row group 13:   4,484 rows, book_id from 2055 to 2598
row group 14:   2,781 rows, book_id from 2598 to 3000
```

**Fifteen row groups, and only the last can hold a book from 2,900 up.** The first holds the
searches, whose `book_id` is empty, which is why its range is `None`. The next is book 1 alone, 4,502
events of it, and the one after starts with more: lesson 1's cube makes it the most popular book by
far. Each later row group spans
a wider range of books, because each book further along is rarer.

**The time hardly came down**, 5.1 seconds against 5.4, because opening 365 files and
reading 365 footers is a cost the sorting does not touch. On data where each file holds many row
groups of a large table, the saving is closer to the rows.
