---
format: 5
course: streaming
---

# streaming

**Streaming and Event Processing** · `co-t8j1zx8b` · 70 h declared · advanced · 17 lessons · `data` · paid

## Reach

In **1 track** — `data-platform`(2).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `python` — the language the consumers are written in.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 17 |
| **hours per lesson** | **4.12** |
| section budget | ~150, about 8.8 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a Kafka broker, and producers and consumers that keep running** |
| browser · database | no · no — a log instead, which is the point |
| exercises **blocked** | **~500 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~65 — partitions and offsets, a consumer group rebalancing, each window type over a timeline, a watermark passing late data |

## Ageing

**Low to moderate.** Kafka's model is stable; Flink, Kafka Streams and Debezium move faster.

## Flags

**1 ·** **A long-running process is a new kind of environment.** Every runtime the sweep has asked for so far starts, does something and exits — a shell command, a query, a training loop. A stream **has no end**, and an exercise about consumer lag or backpressure requires the student's consumer to be running while data arrives. Whatever the sandbox becomes, "a process that stays up and is observed" is not a variation on "run this file".

**2 ·** **Event time against processing time is the hardest idea in the category and the most gradeable.** Lessons 9 to 11 — event time, windows, watermarks and late data — reduce to "given these timestamps and this window, which events are in it", which is `numeric` and `ordering` on paper with no broker at all. **The conceptual half is publishable now**, and it is the half students get wrong.

**3 ·** **Position 2 of `data-platform`, immediately after `bigdata`.** That track is seven courses and this is the second; it never appears anywhere else. Narrow reach, heavy environment — and the same clock problem `pipelines-etl` has, in a harder form.
