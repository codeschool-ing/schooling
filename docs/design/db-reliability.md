---
format: 5
course: db-reliability
---

# db-reliability

**Backup, Replication and High Availability** · `co-1zddx7hz` · 70 h declared · advanced · 24 lessons · `data` · paid

## Reach

In **1 track** — `dba`(8).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `db-administration` — the server, its write-ahead log, its configuration and its logs.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 24 |
| **hours per lesson** | **2.92** |
| section budget | ~150, about 6.2 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **at least two database servers, a way to fail one over, and permission to destroy either** — the heaviest environment in the category |
| browser · database | no · **yes, plural, and the point is what happens when one dies** |
| exercises **blocked** | **~550 (75%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~70 — a replication topology, a timeline through point-in-time recovery, split-brain drawn as two primaries, a failover sequence |

## Ageing

**Low.** Failure modes do not go out of date.

## Flags

**1 ·** **The most destructive environment the sweep has asked for.** Lesson 1 is *"The only backup that counts is the one you have restored"*, lesson 7 is restore drills, lesson 15 is failover, lesson 17 is split-brain and fencing, lesson 23 is *"Killing the primary on purpose, in a rehearsal"*. **A student who cannot destroy the database has not taken this course** — which puts it beside `kubernetes` and `virtualization` in the class of courses whose environment is not a smaller version of somebody else's.

**2 ·** **And this repository already owns the shape of the answer.** `tools/restore-drill` exists and runs a restore against a real database in CI. That is lesson 6 and lesson 7 as a working artefact — **the only case in the whole sweep where a course's hardest exercise already exists as a tool in the repository that would teach it.** Whether it can be turned outward is a real question and worth asking before anything is built from scratch.

**3 ·** **Seventy hours where the wrong answer is invisible until the day it matters.** That makes `ordering` unusually apt — detect, decide, communicate, write it up — and makes a written RPO/RTO number a `numeric` item. The material can be substantially graded without the environment, and then means nothing without it, which is the honest tension to design against rather than paper over.
