---
title: Combiners, or reducing before the shuffle
version: 1
---

**A *combiner* is a reducer that runs on the map side**, on each map task's own output, before
anything is sent to the reducers. If one map task has emitted `view\t1` about two million times, a
combiner turns that into one pair, `view` with its total, and only that crosses the network.

Add one argument, `-combiner`, and use the reducer as the combiner too:

```
ana@lab:~/big$ time hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.5.0.jar -D mapreduce.local.map.tasks.maximum=3 -files mapper.py,reducer.py -mapper 'python3 mapper.py' -combiner 'python3 reducer.py' -reducer 'python3 reducer.py' -input /raw/clicks-2025.csv -output /out/kinds-combined 2> combined.log

real	0m35.309s
user	1m33.777s
sys	0m6.410s
ana@lab:~/big$ sed -n '/mapreduce.Job: Counters/,$p' combined.log | grep -E 'Combine|Reduce shuffle bytes|Spilled'
		Combine input records=24000000
		Combine output records=40
		Reduce shuffle bytes=684
		Spilled Records=80
```

**Shuffle bytes went from 223,679,952 to 684**, and the job took about half the time. Each of the ten
map tasks combined its 2.4 million pairs into four, and the reducer received forty pairs instead of
24 million. Spilled records fell from 48 million to 80.

**A combiner is only correct when the reduce can be done in pieces.** Hadoop may run the combiner
zero times, once or several times on the same data, so the answer has to be the same whichever it
does:

- **Sums, counts, minimums and maximums** combine: the sum of partial sums is the sum.
- **An average does not**, directly: the average of averages is wrong when the pieces have different
  sizes. Emit the sum and the count instead, combine those, and divide at the end.
- **A count of distinct values does not**, as lesson 1's question shows. A map task that saw visitor
  `v0094455` look at book 9 three times can reduce that to one, but it cannot know whether another
  map task saw the same visitor, so the partial counts do not add up. Only the exact list of visitors
  does, and that is no smaller.

`reducer.py` is a sum, so it is a valid combiner of itself. That is common and not guaranteed, and a
combiner that is not valid does not fail: it gives a wrong number.

Spark applies the same idea without being asked. A `groupBy(...).count()` in Spark computes partial
counts in each task before the shuffle, which lesson 7 shows in its plans as the two halves of an
aggregation.
