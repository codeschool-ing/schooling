---
title: ORC
version: 1
---

**ORC is the other columnar format, born in the Hive project in 2013, the same year as Parquet**,
and built on the same ideas: data in column chunks, light encodings, a footer with statistics. Where
Parquet has row groups, ORC has *stripes*, 64 MB by default; inside each stripe it keeps an index
with the minimum and maximum of each column for every 10,000 rows, so a reader can skip at a finer
grain than a whole stripe.

In section 04 ORC came out the smallest of seven, 6.1 MiB against Parquet's best of 7.2, and Spark
needed no options to get there: ORC's run-length encoding for integers, which its timestamps use as
well, includes deltas and is always on, and in this version of Spark the codec is zstd. Reading it
back was slower than the Parquet files on this lab, 4.3 seconds against about 2.

**The choice between them is rarely about the bytes.** Both are open, both are read by every engine
that matters, and either is far better than CSV for analysis. What decides it is the rest of the
system:

- **Parquet is the default of Spark and of the open table formats** of lesson 11, and the format most
  tools outside the Hadoop world read and write: pandas, DuckDB, Arrow, the cloud warehouses.
- **ORC is the default of Hive**, and Hive's transactional tables require it. A lake built around Hive
  in the 2010s is often ORC throughout.

Both also support **bloom filters**, a per-row-group summary that answers "this value is certainly
not here" for a column whose minimum and maximum say nothing, such as a visitor id where every row
group holds ids from `v0000000` to `v1999999`. They are switched on per column when writing, cost
space in every file, and pay off only for equality filters on such columns.
