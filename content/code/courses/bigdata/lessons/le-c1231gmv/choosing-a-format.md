---
title: Choosing a format
version: 1
---

**The three formats solve the same problem, and since 2023 they have been converging.** Each has
added what the others had: Delta has deletion vectors and can write Iceberg's metadata beside its own,
Iceberg has row-level deletes and merges, and Apache XTable translates a table's metadata between all
three. The differences that are
left are of emphasis.

| | Delta Lake | Apache Iceberg | Apache Hudi |
|---|---|---|---|
| began at | Databricks, 2019 | Netflix, 2018 | Uber, 2017 |
| metadata | a log of JSON commits, checkpointed to Parquet | metadata files, manifest lists and manifests | a timeline of commits, and a metadata table |
| strongest at | Spark, and Databricks' platform | many engines, through catalogues | frequent upserts and incremental reads |
| a commit is | creating the next log file | swapping the catalogue's pointer | completing an instant on the timeline |

**Choose by what reads the table, not by the table.** A lake read only by Spark is well served by
any of them, and Delta is the least to set up. A lake read by Spark, Trino, Flink and a cloud
warehouse is what Iceberg's catalogues are for, and it is the one most engines now support. A table
that takes a stream of corrections every few minutes is Hudi's case. A team rarely gets to choose
from scratch: the platform it runs on has usually chosen.

**What all three make possible is what this lesson measured.** A retried job does not double the
data, and a deletion does not mean rewriting files by hand. A table can be read as it was, and a
compaction does not break the readers already running. They do not make the files any smaller
or a query any faster by themselves; lesson 10's choices are made underneath, and still matter.
