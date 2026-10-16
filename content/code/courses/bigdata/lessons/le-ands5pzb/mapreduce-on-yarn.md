---
title: MapReduce on YARN
version: 1
---

**Lesson 4's streaming job ran on MapReduce's local runner: one Java process, every task a thread.**
With `mapreduce.framework.name` set to `yarn`, the same command becomes a YARN application. The only
change is the queue, named with `-D`:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.job.queuename=nightly -files mapper.py,reducer.py -mapper 'python3 mapper.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds-yarn 2> kinds-yarn.log
packageJobJar: [/tmp/hadoop-unjar3357421975958680633/] [] /tmp/streamjob9869232074237175939.jar tmpDir=null

real	1m52.910s
user	0m9.873s
sys	0m0.807s
ana@lab:~/big$ hdfs dfs -cat /out/kinds-yarn/part-00000
cart	1920654
purchase	959814
search	1920318
view	19199214
```

**The same four counts, and it took nearly twice as long**: 1 minute 53 seconds against lesson 4's
1 minute 1. Nothing went wrong. On YARN every map task is a container, and every container is a new
Java process started, given its classpath and stopped, where the local runner reused one process for
everything. And the nightly queue's 70% of 6 GB is about 4.2 GB, room for the ApplicationMaster and
seven tasks of 512 MB at a time, on four cores shared by all of them.

The counters at the end of `kinds-yarn.log` say what the job was:

```
ana@lab:~/big$ grep -E 'Launched (map|reduce) tasks|Killed map tasks|local map tasks' kinds-yarn.log
		Killed map tasks=2
		Launched map tasks=10
		Launched reduce tasks=1
		Rack-local map tasks=10
```

**Ten map tasks, one per 128 MB block of the 1.2 GB file**, as lesson 4 counted them, and one
reduce. **Two more attempts were killed**: MapReduce on YARN runs a second copy of a task that falls
behind, lesson 2's speculation, which is on by default here, and stops whichever copy finishes second.
**And all ten counted as rack-local, not data-local**, lesson 3's locality one level down. The
NodeManager calls this machine `lab` and lesson 3's datanodes call themselves `127.0.0.1`, so YARN
could not see that the block and the task were on the same machine. On a real cluster with names that
agree, most maps are data-local, and a job whose maps are not is reading its input across the
network.

On a real cluster this is what YARN is for. The containers spread over hundreds of machines, the
ApplicationMaster restarts the tasks of a machine that dies, and the start-up cost of a container is
small next to a task that reads a block for a minute. On one machine it is all cost, which is the same
lesson as lesson 1's: the machinery of a cluster pays for itself only when the work needs a cluster.
