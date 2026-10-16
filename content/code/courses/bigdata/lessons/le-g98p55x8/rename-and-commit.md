---
title: Why the missing rename matters
version: 1
---

**Spark finishes a write with a rename, and it does so because HDFS makes a rename cheap and
atomic.** Each task writes its output into a temporary directory under the destination. When the
task succeeds, its files are moved into place; when the whole job succeeds, the job's are, and the
`_SUCCESS` file of lesson 1 appears. A task that failed or ran twice, as lesson 2's did, leaves its
files in a temporary directory that nobody moves, and they are deleted. The output a reader sees is
exactly one copy of each task's work, and it appears all at once.

That protocol is called the *output committer*, and on HDFS it is close to free: every move is one
namenode operation.

On an object store the same protocol runs, and every one of those moves becomes a copy of every
byte followed by a delete, request by request. Two things go wrong:

- **It is slow.** A job that wrote 10,000 files spends its last minutes copying all of them again,
  on one machine, after every task has finished. The data is written twice.
- **It is not atomic.** Midway through the moves, half the files are in place and half are not. A
  reader that lists the directory in that window sees a partial result and has no way to know. If
  the driver dies in that window, lesson 2's one unrecoverable failure, the partial result stays.

The cures are worth knowing by name, because you will meet them in a job's configuration:

- **The S3A committers**, which Hadoop's connector provides. Each task uploads its file in parts and
  leaves the upload unfinished; the job's commit finishes every upload at once, which an object
  store does as one request per file without copying. Faster, though still not atomic across
  files.
- **A table format**, lesson 11's subject. Delta Lake, Iceberg and Hudi never rename anything: a
  write adds new files under new names, and then a single small file, the commit, says which files
  make up the table. Writing that one file is atomic on any object store, so the table changes all
  at once. That is most of the reason table formats exist.

**The point to carry away** is that "the same code with `s3a://` instead of `hdfs://`" is true of the
reading and only half true of the writing. A job moved from HDFS to an object store without changing
its committer runs, gives the right answer most of the time, and is slow and occasionally wrong in a
way no error message announces.
