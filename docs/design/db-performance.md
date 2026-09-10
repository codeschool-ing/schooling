---
format: 5
course: db-performance
---

# db-performance

**Database Performance and Scale** · `co-m143eq77` · 70 h declared · advanced · 24 lessons · `data` · paid

## Reach

In **1 track** — `dba`(7).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `db-administration` — a server the student runs, and the vocabulary of its internals.

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
| runtime | **the same server, plus a workload big enough to be slow** |
| browser · database | no · **yes, and it must contain enough rows to have a plan worth reading** |
| exercises **blocked** | **~500 (70%), and blocked twice over** — see flag 1 |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~65 — each scan and join type, a plan tree annotated, an index's write tax, a lock wait graph |

## Ageing

**Low.** Planners change slowly and the reasoning does not.

## Flags

**1 ·** **It needs a slow database, which is harder to provide than a database.** Every other course in the catalogue is satisfied by an environment that *works*; this one needs one that **misbehaves reproducibly** — stale statistics, a duplicated index, a lock somebody else is holding, a partition the query ignores. A seeded fixture with a hundred rows demonstrates none of it, and the exercises that matter are exactly the ones a toy dataset cannot carry. That is a data-volume problem sitting on top of the environment problem, and it is specific to this course.

**2 ·** **Lesson 24 is the course grading itself** — *"The optimisation that was not needed: measuring the gain afterwards"* — and it is the one lesson that could be graded by `numeric` without any runtime at all: given a before and an after, was this worth doing.

**3 ·** **`EXPLAIN` output is text, and text is comparable.** Where the runtime is blocked, a plan pasted into a `cloze` or an `ordering` item still teaches reading it, which is the course's core skill. **That is the degraded version worth designing on purpose**, the way `git` is publishable degraded.
