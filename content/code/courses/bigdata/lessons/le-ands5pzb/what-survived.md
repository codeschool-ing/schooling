---
title: What survived
version: 1
---

**The ideas of Hadoop survived better than its programs.** Every one of them is in what replaced it:

- **HDFS's blocks, replicas and locality** became object storage's durability and the cloud's
  separation of storage from compute. The cost of that separation is the locality lesson 3 measured,
  and columnar formats with pruning, lessons 6 and 10, are how it is paid back.
- **YARN's containers and queues** became Kubernetes' pods and namespaces with quotas, lesson 13, with
  Spark asking for executors the same way.
- **MapReduce's model** became Spark's stages: a map side, a shuffle by key, a reduce side, with the
  intermediate results kept in memory instead of written to HDFS between jobs.
- **Hive's metastore** became the catalogue of every engine, and its partitions the directories of every
  lake. **HiveServer2** is the shape of every SQL endpoint over a lake.
- **HBase** is still HBase, for the applications that need it, next to its cloud cousins built on the
  same Bigtable design.

What a data engineer meets today is usually a mix: a YARN cluster on premises that has run for ten
years and a Kubernetes or managed one beside it, a metastore both of them share, and Parquet files
under all of it. Lesson 13 is the other half of that picture.

Before leaving, stop what this lesson started; the standalone cluster stays up for the next one:

```sh
stop-hbase.sh
sh hdfs.sh stop
```
