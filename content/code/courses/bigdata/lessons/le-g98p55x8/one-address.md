---
title: Every worker has to see the same file
version: 1
---

**In lessons 1 and 2, every job read `data/raw/clicks` from your disk, and that only worked
because there was one disk.** The driver told each executor "read this file, from this byte to that
one", and each executor opened the path on its own machine. All three executors were on the same
machine, so all three found the file.

On a real cluster that instruction fails at once. Each worker is a different computer with its own
disk, and `/home/ana/big/data` exists on none of them, or worse, exists on one of them with
yesterday's contents. **A cluster needs a filesystem whose paths mean the same thing on every
machine**, and the data has to be spread over the machines too, because the point of a cluster is
that each machine reads its own share from its own disk.

There are two ways to get that, and this lesson runs both:

- **A distributed filesystem**, HDFS, which spreads files over the disks of the same machines that
  run the jobs. It came with Hadoop in 2006 and is still what most on-premises clusters store their
  data in.
- **An object store**, such as Amazon S3, Google Cloud Storage or Azure Blob Storage, which is a
  separate service reached over the network. The machines that compute keep no data at all, and
  this is how most clusters in a cloud are built.

They look alike from a Spark program, where only the start of the address changes, `hdfs://` or
`s3a://`. Underneath they make different promises, and a job that relies on one of HDFS's promises
behaves differently, and sometimes wrongly, on an object store. Sections 09 and 10 are about that
difference.
