---
title: Choosing between them
version: 1
---

**The question that decides it is rarely speed. It is who will run the thing at three in the
morning, and what it has to read and write.** All three count Ponto Final's sales per window
correctly; you have now seen each one do it. What differs is what each one asks of the team that
keeps it alive.

| | Spark Structured Streaming | Flink | Kafka Streams |
|---|---|---|---|
| latency | a batch interval: a second or more in practice | milliseconds | milliseconds |
| state | in the checkpoint directory, on shared storage | in a state backend, snapshotted to shared storage | in local stores, backed up to Kafka topics |
| event time and watermarks | yes, one watermark per query | yes, the most complete: per partition, idleness, late-data outputs | yes, through grace periods on windows |
| sources and sinks | files, tables, Kafka and many more | Kafka, files, databases and many more | Kafka only |
| what you deploy | a Spark cluster, or a session in your job | a Flink cluster | your own application, as many copies as you need |
| languages | Python, SQL, Scala, Java | SQL, Java, Python | Java and other JVM languages |
| who runs it | whoever already runs Spark for batch | a team that runs Flink as a platform | the team that owns the application |

Read the table by the last row first. **A team that already runs Spark for its nightly jobs pays
almost nothing to add a stream**: the same cluster, the same DataFrames, the same people, and the
same code can run as a batch with `availableNow`. That is often the deciding argument, and it is a
good one whenever a second of latency is acceptable.

**Flink is the one to choose when the stream is the product**: when results are needed in
milliseconds, when state is large, when there are many sources and the event-time rules are
demanding. It is also a cluster with its own way of being operated, upgraded and recovered, and
somebody has to know it well.

**Kafka Streams fits a service that already reads Kafka** and needs a count, a join or a
deduplication inside it. Nothing new to install or operate; the scaling is the service's own. The
price is that everything in and out is a Kafka topic, it is Java, and its internal topics multiply:
two counts in section 03 already made four.

## For Ponto Final

The chain's needs, from lesson 1, are a stock count on the website, alerts when a shop sells out,
the warehouse loaded from the same events, and a team of two or three people. A reasonable reading:

- The **warehouse load** is a batch, and Spark with `availableNow` over the same topic does it with
  code the team can read.
- The **stock count per book** is state per key, updated by every sale, inside the service that
  answers the website. That is a Kafka Streams shape: a table kept by the application, with no
  engine to run beside it.
- **Nothing here needs Flink yet.** It earns its place when a second-long delay costs money, or the
  state outgrows what an application can hold. Choosing it on day one means operating a cluster for
  a problem two tools already solve.

That is a reading, not a rule; a team with Flink experience and none of Java would weigh it
differently. What does not change is the method: start from who operates it and what it touches,
and look at latency last.
