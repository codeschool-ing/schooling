---
format: 5
course: bigdata
---

# bigdata

**Big Data and Distributed Processing** · `co-acg3xn9b` · 70 h declared · advanced · 14 lessons · `data` · **free**

## Reach

In **1 track** — `data-platform`(1).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `python` — the language Spark is driven from here. Not `python-data`: this is DataFrames of a different kind.

**Leaves ready:** **nothing** by name, and in practice the distributed vocabulary `streaming` and `ml-mlops` lean on.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 14 |
| **hours per lesson** | **5.00** |
| section budget | ~150, about 10.7 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a Spark cluster, or a convincing single-node lie about one** |
| browser · database | the Spark UI is a browser interface, and reading it is lesson 7 and 8 · no, and a filesystem instead |
| exercises **blocked** | **~500 (70%), and one of them cannot be faked** — see flag 2 |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — a shuffle, skew as a histogram, a broadcast join, the Catalyst plan, partitions across nodes |

## Ageing

**Moderate.** Spark is stable, the table formats are not: Delta, Iceberg and Hudi are lesson 11 and are actively competing.

## Flags

**1 ·** **Free, and nobody arrives at it free — the third instance, which closes the case.** It is position 1 of `data-platform`, which declares `continues: data`, so `C-28` makes 70 advanced hours the free sample of a track no beginner can reach. `process-management` and `architecture-role` are the other two. **That is all three continuation tracks in the catalogue, three for three** — the free-sample rule is not misfiring occasionally, it is wrong in every case where a track continues another, and the field that would fix it (`continues`) is already in the data.

**2 ·** **Lesson 1 is the course's premise and a sandbox cannot stage it.** *"When data stops fitting on one machine"* — the entire subject is what happens past the point where a laptop copes, and a teaching cluster is by construction small enough to cope. A single-node Spark teaches the API and hides the only thing the course is about: shuffle, skew and the cost of moving data between machines. **The honest options are a real multi-node cluster or a course that teaches the reasoning from measurements somebody else took**, and the second is smaller than the lesson list promises.

**3 ·** **Fourteen lessons at 10.7 sections each**, and the last one is *"Tuning a job, and what an hour of cluster costs"*. Cost again as subject matter, and again unfeelable without a bill — the third time in this category after the vendor family and `deep-learning`.
