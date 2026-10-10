---
title: Watermarks
version: 1
---

**A watermark is a time W, carried along with the stream, that means: events with a time before W
are not expected any more.** When W passes the end of a window, the window is complete as far as
the processor will ever believe, and its result can be emitted.

The usual way to compute one is the simplest that could work, and it is the one Flink calls
bounded out-of-orderness:

```python
watermark = latest_event_time_seen - bound
```

The bound is how out of order the processor allows events to be. With a bound of two minutes, a
processor that has just seen a sale from 09:12:30 sets its watermark to 09:10:30, and that passes
the end of the 09:05 to 09:10 window, which is emitted. A sale that happened before 09:10:30 and
arrives after this moment is **late**: it is behind the watermark, and the processor has already
said that it did not expect it.

Two properties make it usable:

- **It only moves forward.** A sale from 09:08:50 arriving after one from 09:13:05 does not pull
  the watermark back, because the latest time seen is still 09:13:05. If it did move back, a
  window already emitted would be open again, and "emitted" would mean nothing.
- **It is made of event times.** Read the same topic tomorrow and the watermark passes 09:10 at the
  same record, so the same windows close with the same contents. Nothing about it depends on when
  the processor runs or how fast.

@@fig:l11-watermark@@

## A heuristic, and the perfect kind

The bound is a guess about the stream, and the guess can be wrong in both directions. Too small,
and ordinary slow deliveries arrive behind the watermark and are treated as late. Too large, and
every window waits longer than it needed to, for events that were never coming. A watermark
computed this way is called **heuristic**, because it is an estimate.

A **perfect** watermark is possible only where the source knows its own order: a single till
writing to its own partition, in the order of its sales, with no buffering, could tell the
processor exactly how far it has got. Real systems combine many sources, buffer, and retry, so
almost every watermark in practice is a heuristic, and the right bound is a measurement, which is
the section on choosing it.

## Who carries it

In Flink the watermark is a special element that travels inside the stream, from the sources
through every operator, and an operator with several inputs forwards the lowest of their
watermarks. Spark Structured Streaming computes one watermark per query from the latest event time
seen, with the bound given by `withWatermark("at", "2 minutes")`, which lesson 12 uses. Kafka
Streams keeps a **stream time** per task, the highest timestamp seen, and its **grace period** is
the bound: a window accepts records until stream time passes its end plus the grace. Three
vocabularies, one idea: **the latest event time, minus a bound, moving only forward.**
