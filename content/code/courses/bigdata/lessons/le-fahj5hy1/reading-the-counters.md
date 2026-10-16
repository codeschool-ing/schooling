---
title: Reading the counters
version: 1
---

**A MapReduce job ends by printing its *counters***, totals kept by every task and added up at the
end. They are the first place to look when a job is slow, because they say how much data each step
handled. The ones that matter, from the log of the last section:

```
ana@lab:~/big$ sed -n '/mapreduce.Job: Counters/,$p' kinds.log | grep -E 'Map (input|output) records|materialized|Reduce (shuffle bytes|input groups)|Spilled|FILE: Number of bytes written'
		FILE: Number of bytes written=1911465611
		Map input records=24000000
		Map output records=24000000
		Map output materialized bytes=223679952
		Reduce input groups=4
		Reduce shuffle bytes=223679952
		Spilled Records=48000000
```

Read them in the order the data flowed:

- **Map input records, 24,000,000.** Every event, read once.
- **Map output records, 24,000,000.** One pair per event: the mapper never filters and never
  combines.
- **Map output materialized bytes, 223,679,952.** What the map tasks wrote to their local disks for
  the reducers to fetch: 224 MB of `view\t1` and its cousins, each pair with a little framing.
- **Reduce shuffle bytes**, the same 223,679,952: all of it travelled to the one reduce task. On a
  cluster that is network traffic, from every machine that ran a map task to the one that runs the
  reducer.
- **Reduce input groups, 4.** Four different keys, so the reducer printed four lines.
- **Spilled records, 48,000,000.** Every pair was written to disk twice, once by the map side when
  its buffer filled and once by the reduce side while merging. A record spilled is a record that did
  not fit in memory at that moment.
- **FILE: Number of bytes written**, about 1.9 GB on the local disk, against an input of 1.3 GB.

**224 MB moved and 1.9 GB written to disk to produce 58 bytes of answer.** None of it is a mistake;
it is what the model does when a mapper emits one pair per record and nothing reduces them early.
The next section changes one argument and most of it goes away.
