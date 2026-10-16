---
title: Managed services
version: 1
---

**A managed service runs the cluster and leaves the job to you.** Every large cloud sells Spark this
way, and they differ mostly in how much of the cluster they still let you see:

| | what you ask for | what the provider runs | how it is billed |
|---|---|---|---|
| **Amazon EMR**, **Google Dataproc**, **Azure HDInsight** | a cluster of a given size, with Spark and Hadoop installed | the machines, the installation, YARN | per machine-hour while the cluster exists |
| their *serverless* modes, **AWS Glue** | a job, with a ceiling on its resources | everything, including the size of the cluster | per unit of work actually used |
| **Databricks**, **Microsoft Fabric** | a workspace, notebooks, jobs and a catalogue | clusters started and stopped for you, a table format, governance | per unit of compute, on top of the cloud's machines |

**None of these was run for this course**, because each needs an account with a card behind it and
bills from the first minute. What can be said without running them is what they change and what they
do not.

**They change who is woken up at night.** Installing Spark, upgrading Java, replacing a dead disk,
patching the operating system: the work of lessons 1, 3 and 12 is the provider's. A cluster that
exists only while a job runs, started in a minute and gone when the job ends, is the normal way to
run batch work in the cloud. It makes lesson 2's sizing question a question about each job instead
of
about a fleet.

**They do not change anything in lessons 5 to 11.** A job reads Parquet from an object store, plans
through Catalyst, shuffles, skews, spills and caches on a managed cluster exactly as on this one. The
default executor sizes, the shuffle partitions, the file sizes and the sort order are still yours to
choose, and a bad choice is billed by the hour instead of costing a slow evening. Lesson 14 puts
prices on both.

**What lock-in there is lives above Spark**: the provider's catalogue, its table format extensions,
its
notebooks, its job scheduler. A job written against `spark.read.parquet` and plain SQL moves between
them with its configuration; a job written against a provider's own APIs moves with a rewrite.
