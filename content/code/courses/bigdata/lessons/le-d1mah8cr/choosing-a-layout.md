---
title: Choosing how to write
version: 1
---

**Every decision of this lesson is made when the data is written, and paid for every time it is
read.** A table written once and read daily for a year is read three hundred times, so a write that
costs twice as much and makes every read faster is a bargain. The lesson's measurements, as rules:

- **A columnar format for anything read by analysts.** CSV is for arriving, not for staying: January
  took 6.8 seconds to read as gzipped CSV and under 3 as any Parquet file.
- **A stronger codec than the default** for data read more often than written: zstd cut Snappy's 33.0
  MiB to 19.6, and read no slower.
- **Timestamps as 64-bit integers** in Parquet, `spark.sql.parquet.outputTimestampType` set to
  `TIMESTAMP_MICROS`, unless an old reader needs `INT96`.
- **Version 2 pages** where every reader of the table supports them, which current Spark, Arrow,
  DuckDB and Trino do: the delta encodings halved the file again.
- **Sort by the column most queries filter on**, within the partitions, and accept what it costs the
  other columns.
- **Files of hundreds of megabytes**, not one per hour of data, and row groups of the default size.
  Lesson 8's partitioned write and lesson 3's small files are the same rule from the other side.

None of these is free to change later. **A table's layout is changed by rewriting it**, which for a
large table is a job of its own; lesson 11's table formats make that rewrite safe to run while others
read, and lesson 14 puts a price on it.
