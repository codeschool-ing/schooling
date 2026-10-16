---
title: The same two programs, run by Hadoop
version: 1
---

**Hadoop Streaming runs any program that reads standard input and writes standard output as a
mapper or a reducer.** It comes with the Hadoop you installed in lesson 3, as a jar, and takes the
two programs, an input in HDFS and an output directory that must not exist yet:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files mapper.py,reducer.py -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds 2> kinds.log

real	1m1.316s
user	2m1.648s
sys	0m7.981s
```

A minute for 1.2 GB. `-files` ships the two programs to wherever the tasks run. `mapreduce.local.map.tasks.maximum=3`
lets three map tasks run at once. Hadoop prints several hundred lines of progress on its error
stream, so `2> kinds.log` keeps them in a file to read afterwards. The answer is in HDFS, in one file
per reduce task:

```
ana@lab:~/big$ hdfs dfs -ls /out/kinds
Found 2 items
-rw-r--r--   3 ana supergroup          0 2026-10-15 22:00 /out/kinds/_SUCCESS
-rw-r--r--   3 ana supergroup         58 2026-10-15 22:00 /out/kinds/part-00000
ana@lab:~/big$ hdfs dfs -cat /out/kinds/part-00000
cart	1920654
purchase	959814
search	1920318
view	19199214
```

**The same four numbers as the pipe, for the whole year this time.** 19,199,214 views, the same count
Spark printed in lesson 3.

**Where this ran.** A Hadoop installation with no setting for `mapreduce.framework.name` runs a job
with MapReduce's *local runner*: every map and reduce task as a thread inside one Java process, on
the machine that submitted it. The input came from HDFS and the output went back there, and every
step of the model happened: ten map tasks, one per block, a shuffle through files on the local disk,
a sort and a reduce. What the local runner does not do is spread tasks over machines. Lesson 12 starts
YARN, Hadoop's cluster manager, and runs this same command on it.
