---
title: Notebooks: the same Spark, written as code
version: 1
---

**A notebook is a document of cells, code and its output, attached to a Spark session.** Each cell
runs on the cluster behind the session, in Python, SQL, Scala or R, and the output stays under it.
Written for the night's job, a notebook is the program of the next section run by Spark instead of
DuckDB: read the raw files, apply the rules, write the curated table. This section is taught from
Microsoft's and Databricks' documentation and was not run.

## Three places a notebook runs on Azure

| | what runs it | what it is billed by |
|---|---|---|
| **Synapse** | an Apache Spark pool of the workspace, with a node size, autoscaling and an automatic pause after idle minutes | vCore-hours of the pool while it runs |
| **Fabric** | a Spark session started from the workspace's pool, warm starter pools by default | capacity units of the lesson 17 capacity |
| **Azure Databricks** | a cluster or serverless compute in a Databricks workspace | DBUs plus, for classic clusters, the virtual machines; lesson 21 |

**The code is the same Spark in all three**, with small differences in how each reads storage and
which libraries it has. A notebook written against Delta tables and `abfss://` paths moves between
them with changes to its first cell, which is part of why teams that expect to change platform write
code rather than draw boxes.

## What code gives, and what it asks

**What it gives is everything a program has.** A notebook lives in Git as a file, and a change to it is
a diff a colleague can review line by line. Its rules can be functions, tested on four rows the way
the testing section does. It can use any library the cluster can install, call an API, or handle a file
format no data flow box knows. And the same notebook runs from the editor while it is written and
from lesson 19's pipeline at night, through a notebook activity, without being rewritten.

**What it asks is a person who writes and reads code, and the discipline to write it well.** A
notebook is as easy to make unreadable as any program: one long cell that reads, cleans and writes,
with values pasted in while exploring and never taken out. Notebooks also carry their outputs, which
can include rows of data; a notebook committed to Git with yesterday's customers in its cells has put
personal data somewhere it was never meant to be, and clearing outputs before committing is the
habit that prevents it.

## Run by whom

**At three in the morning nobody opens a notebook.** It runs as a job: a pipeline's notebook activity
in Data Factory or Fabric, or a Databricks job, lesson 21. The job passes parameters, the night's
date among them, into the notebook's first cell, which is the same contract as the pipeline parameter
`day` in lesson 19. A notebook that only works when somebody runs its cells in order by hand is not
yet a job, however well it ran yesterday.
