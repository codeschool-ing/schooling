---
title: Checkpointing
version: 1
---

**A checkpoint computes a DataFrame, writes it to files, and replaces its plan with a read of those
files.** The lineage is cut: whatever came before no longer exists as far as Spark is concerned.
The same program with `checkpoint` on the command line checkpoints the ranks every five iterations:

```
ana@lab:~/big$ spark-submit lineage.py checkpoint
WARNING: Using incubator modules: jdk.incubator.vector
02:41:15 WARN SparkContext: Spark is not running in local mode, therefore the checkpoint directory must not be on the local filesystem. Directory 'file:///home/ana/big/checkpoints' appears to be on the local filesystem.
iteration  5: plan of    4 lines,  55.8 s, top book 1
iteration 10: plan of    4 lines,  10.0 s, top book 1
iteration 15: plan of    4 lines,   8.6 s, top book 1
iteration 20: plan of    4 lines,   7.7 s, top book 1
twenty iterations: 82.1 s
```

**The plan stayed at four lines**, a scan of the checkpoint files and the steps since, and after the
first five iterations each block of five took 8 to 10 seconds where the growing plan had taken 28
to 41. The whole run took 82.1 seconds, against 154.7 without checkpoints.

**The warning is about the directory, and on a real cluster it is right.** A checkpoint is written by
the executors and read back by whichever executor runs the next task, so it has to be on storage
every machine can reach: HDFS, or an object store. A directory on one machine's local disk works
here only because every process of this lab shares one disk, and Spark says so rather than assume
it.

Two kinds of checkpoint, for two different needs:

| | `checkpoint()` | `localCheckpoint()` |
|---|---|---|
| where it writes | the checkpoint directory, on shared storage | the executors' own block storage |
| survives a lost executor | yes | no, and the lineage it replaced is gone |
| costs | a write to shared storage | about what a cache costs |

**`localCheckpoint()` is for cutting a plan, not for safety.** It is a cache that forgets where it came
from: fast, and a lost executor loses its partitions with nothing to rebuild them from, so the
application fails. Use it to keep a loop's plan small when executors are not expected to fail, and
`checkpoint()` when a failure must not cost the whole run.

**A checkpoint is not a cache, and the two combine.** A checkpoint is written to files and read back
from files; a DataFrame that is checkpointed and then used several times is read several times. The
usual pattern in a long loop is to checkpoint every few iterations, which bounds the plan, and to
cache whatever each iteration reads more than once.
