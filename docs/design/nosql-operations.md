---
format: 5
course: nosql-operations
---

# nosql-operations

**NoSQL: Modelling and Operations** · `co-qcjqf4dj` · 60 h declared · intermediate · 22 lessons · `data` · paid

## Reach

In **1 track** — `dba`(11).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `db-administration` — running a database as a process rather than querying one.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 22 |
| **hours per lesson** | **2.73** |
| section budget | ~129, about 5.9 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **three different database servers** — MongoDB, Redis and Cassandra, each with its own cluster mode |
| browser · database | no · **yes, three of them, and none is the relational one** |
| exercises **blocked** | **~450 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — the five families side by side, a replica set election, a shard key's consequences, a tombstone surviving a delete |

## Ageing

**Moderate.** Three products, each with its own release cadence and its own licence history — MongoDB and Redis have both changed licence in living memory, which is a fact about the material rather than about the video.

## Flags

**1 ·** **Three products in one course, and the environment cost is three.** Unlike the vendor courses, all three are open-source and self-hostable, so this is engineering rather than money — but it is three container images, three cluster modes and three failure vocabularies behind one 60-hour course reached by one track.

**2 ·** **Its last lesson is the honest one and the course should be built around it.** *"Choosing between them, and the honest answer that it should stay relational"* — a NoSQL course that ends by recommending Postgres is telling the truth, and it is the lesson that survives every product on the list being replaced.

**3 ·** **Position 11 of `dba`, behind three prerequisite hops.** `sql-databases` → `db-administration` → here, with `db-performance` and `db-reliability` alongside. Fewest students of the four database courses will reach it, and it has the highest environment cost per student of the four. That ratio argues for it being last of the four to be written.
