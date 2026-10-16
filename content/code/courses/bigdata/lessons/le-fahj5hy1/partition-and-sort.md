---
title: Which reducer gets which key
version: 1
---

**With more than one reduce task, each key has to go to exactly one of them**, always the same one,
or a key's values would be split between two reducers and each would print half a total. The
*partitioner* decides, and Hadoop's default is the one `buckets.py` used in lesson 1: a hash of the
key, modulo the number of reduce tasks.

Ask for two reduce tasks and look at what each received:

```
ana@lab:~/big$ hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files mapper.py,reducer.py -mapper 'python3 mapper.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -numReduceTasks 2 -input /raw/clicks-2025.csv -output /out/kinds-two 2> two.log
ana@lab:~/big$ hdfs dfs -ls /out/kinds-two
Found 3 items
-rw-r--r--   3 ana supergroup          0 2026-10-15 22:02 /out/kinds-two/_SUCCESS
-rw-r--r--   3 ana supergroup         30 2026-10-15 22:02 /out/kinds-two/part-00000
-rw-r--r--   3 ana supergroup         28 2026-10-15 22:02 /out/kinds-two/part-00001
ana@lab:~/big$ hdfs dfs -cat /out/kinds-two/part-00000
purchase	959814
view	19199214
ana@lab:~/big$ hdfs dfs -cat /out/kinds-two/part-00001
cart	1920654
search	1920318
```

**Two output files, one per reduce task, and every kind in exactly one of them.** Which kind went
where is decided by the hash and is not meant to mean anything. Within each file the keys are sorted,
because each reducer's input was; across files they are not, and a job that needs one sorted output
has to ask for a partitioner that splits by ranges of the key instead of by hash.

Two things follow from the partitioner, and both are lesson 8's subject:

- **A reduce task gets all of a key, however much of it there is.** The crawler of lesson 1 is one
  key with 960,905 events. In a job keyed by visitor, one reduce task receives all of them, and the
  job waits for that task while the others sit finished.
- **The number of reduce tasks is a choice, and nothing chooses it for you.** Too few and each is
  large; too many and each is tiny and the output is the small files of lesson 3. Hadoop's default is
  one, which is why the first job wrote one `part-00000`.
