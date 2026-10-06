---
title: Iceberg and Hudi
version: 1
---

Delta Lake is one of three open table formats, and the other two are built on the same idea: data in Parquet files,
plus metadata that says which files make up each version.

**Apache Iceberg**, created at Netflix, keeps its metadata in a tree rather than a flat log: a metadata file for each
version of the table points at a **manifest list**, which points at **manifests**, each listing a set of data files
with their statistics. The tree lets very large tables be planned quickly. Iceberg also tracks columns by id rather
than by name, so renaming a column or changing a partition scheme does not rewrite data, and it has **hidden
partitioning**: a table partitioned by the month of a timestamp is queried with an ordinary filter on the timestamp,
and Iceberg works out which partitions match.

**Apache Hudi**, created at Uber, was built first for tables that receive a steady stream of updates and deletes, such
as a copy of an operational database kept current by change data capture. It offers **merge on read** alongside copy
on write: changes are written to small log files beside the data, and merged at read time until a compaction folds
them in, which makes frequent small updates cheap.

What decides between them is mostly the rest of the stack:

- **Which engines read and write it.** Spark, Trino, Flink, DuckDB, Snowflake, BigQuery, Redshift and Databricks all
  read one or more of the three, and the support differs by engine and by version.
- **Which catalogue** holds the pointer to each table's current metadata. Iceberg in particular relies on a catalogue
  service for its atomic commits, and lesson 12 comes back to catalogues.

The three have also been moving towards each other. Some products now write one table's metadata in more than one
format at once, so a Delta table can be read as an Iceberg table, and the choice matters less each year. **For
modelling, nothing changes**: the star of lessons 2 to 6 is as at home in any of the three as in DuckDB.
