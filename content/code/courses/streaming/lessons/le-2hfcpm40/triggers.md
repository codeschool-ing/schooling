---
title: Triggers, and the one that is not a micro-batch
version: 1
---

Every run so far used `availableNow`: read what is in the topic, in as many batches as the limits
allow, then stop. That is a batch job written with streaming code, and it has its uses. **A trigger
is the setting that decides when the next micro-batch starts**, and the other choices are what make
the same query a stream.

| trigger | when a batch starts | ends |
|---|---|---|
| none given | as soon as the last one finished | never |
| `processingTime="5 seconds"` | every five seconds by the clock; at once if a batch took longer | never |
| `availableNow=True` | at once, until everything present at the start is read | by itself |
| `once=True` | one batch over everything present, ignoring limits | by itself; deprecated in favour of `availableNow` |
| `continuous="1 second"` | there are no batches; the second is how often progress is saved | never |

## A trigger on a clock

To watch a live stream, the topic should receive sales while the query runs. Make the topic again,
empty, so the till's clock starts at 09:00 with nothing ahead of it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic sales
```

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

In the **second shell**, start the query with a five-second trigger and a new checkpoint, since the
old ones describe a topic that no longer exists:

```
ubuntu@stream:~/work$ python spark_sales.py --trigger 5 --checkpoint ~/spark/ckpt/live 2>spark.log
```

In the first, send a hundred sales at ten a second, so that they take ten seconds to arrive:

```
ubuntu@stream:~/work$ python tills.py --count 100 --rate 10
```

**Your batches will not match these**, and that is the point of this run: what lands in each batch
depends on where the five-second ticks fall against the sales, and no two runs cut them in the
same place. What does not change is the shape. A batch ran every five seconds and carried
whatever had arrived since the last one; a window could appear in one batch with part of its sales
and in the next with more; and once the till stopped, the batches stopped printing rows. Stop the
query with Ctrl+C when you have seen enough.

## What it costs to run

While the query is running, the first shell can see what is on the machine. `jps`, which came with
the JDK, lists the Java programs, and `ps` how much memory each process holds:

```
ubuntu@stream:~/work$ jps -l
```

```
ubuntu@stream:~/work$ ps -o pid,rss,comm -u ubuntu --sort=-rss | head -5
```

The largest `java` is Spark, about 600 MB, and the next is the Kafka node, about 400 MB: `RSS` is
in kilobytes. Your Python program, which only sends the query to Spark and waits, is the 50 MB
`python`. **About a gigabyte for a broker and a streaming query**, comfortably inside the 4 GB the
virtual machine has.

```
ubuntu@stream:~/work$ ss -ltn | grep -E "4040|9092"
```

Port 4040 is Spark's web page about the running query, and it listens on `127.0.0.1`, like the
Kafka node, because of the `SPARK_LOCAL_IP` line from section 03.

## Continuous processing

The last trigger in the table is a different engine. **Continuous processing does not cut the
stream into batches at all**: long-running tasks read each record and pass it on as it comes, with
latencies of a few milliseconds instead of hundreds. The price is what it can do. It handles
queries that take one row and give one row, such as projections and filters, and refuses anything
with state, so this lesson's count is refused before it starts:

```
ubuntu@stream:~/work$ python spark_sales.py --trigger continuous --checkpoint ~/spark/ckpt/cont 2>spark.log; grep AnalysisException spark.log
```

The watermark is the first thing it objects to, and the aggregation would be the next. Continuous
processing is also **at-least-once only**, and Spark's own guide still calls it experimental. Spark
4.1 carries a newer low-latency design, a real-time mode, in its Scala engine; the Python
`trigger()` of 4.1.3 has no way to ask for it, and this course does not run it.

So the honest summary for Spark is that it is a micro-batch engine. **For a latency of a second or
two, which is most dashboards, alerts and stock counts, that is enough.** For a reply in
milliseconds, with windows and state, lesson 13's Flink is built for it.
