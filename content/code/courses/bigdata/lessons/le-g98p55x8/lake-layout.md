---
title: Laying out a data lake
version: 1
---

**A *data lake* is files in a distributed filesystem or an object store, organised so that programs
can find what they need without reading everything.** There is no engine in charge of it, unlike a
warehouse: the layout is the only index there is, so the layout is the design.

The convention every engine understands is the one `generate.py` used in lesson 1:

```
data/raw/clicks/day=2025-01-01/part-00006-….csv.gz
data/raw/clicks/day=2025-01-02/part-00041-….csv.gz
…
```

**A directory named `column=value` is a *partition***, in the sense Hive gave the word, and lesson 12
meets Hive: every file under it has that value in that column, and the column is not stored
in the files at all. Lesson 1's Spark job read the directory and found a `day` column that no file
contains. A query that asks for one day can then skip 364 directories without opening them, and
lesson 6 shows Spark doing it.

Three decisions make or break a lake, and each has a rule of thumb:

- **Partition by what queries filter on, and by something with few values.** Day is the classic: a
  year has 365, and almost every question about clicks names a period. Partitioning by visitor would
  give two million directories of tiny files, the small-files problem with a directory for each.
- **Aim for files of hundreds of megabytes**, a few blocks each on HDFS. Fewer means more of the
  overhead of section 07; much larger means a task per file that takes too long and cannot be split
  if the file is compressed whole, as a gzip is.
- **Keep the layers apart.** Most lakes keep the data as it arrived (*raw*, or *bronze*), the same
  data cleaned and typed (*silver*), and tables built for questions (*gold*). The raw layer is never
  edited, so any mistake downstream can be rebuilt from it. `~/big/data/raw` is that layer, and
  lesson 5 writes the next one.

**What a lake does not have, by construction, is anything to stop two writers from colliding**, or a
reader from seeing a half-written partition, or a schema from drifting file by file. Those are what a
warehouse gave you for free. The open table formats of lesson 11 add them back on top of plain
files, and that is why the word *lakehouse* exists.
