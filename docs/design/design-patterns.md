---
format: 5
course: design-patterns
---

# design-patterns

**Design Patterns and Principles** · `co-g2q9fpcc` · 80 h declared · advanced · 19 lessons · `architecture` · paid

## Reach

In **1 track** — `software-architecture`(2).

**Depends on it:** `architecture-modeling`

## Assumes, and leaves ready

**Assumes:** **a language, and it cannot name which one.** No `requires`, position 2 of `software-architecture`, which continues `backend` — and `backend`'s fifth step is a choice between JavaScript, Python, Java and Go. So the student has one of four and the course knows which of them it is only at run time, which is to say never.

**Leaves ready:** patterns, SOLID, TDD and the vocabulary of trade-offs, for `architecture-modeling`, which requires it. **The only prerequisite edge inside `architecture`.**

## Shape

| | |
|---|---|
| declared hours | 80 h |
| lessons | 19 |
| **hours per lesson** | **4.21** |
| section budget | ~171, about 9.0 a lesson |
| exercises | ~800, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **yes, and this is the exception that proves the category** — thirteen of the fourteen courses swept here need nothing, and this one needs a compiler or an interpreter for whichever of four languages the student took |
| browser · database | no · no |
| exercises **blocked** | **~200 (25%)** — every pattern is code, and code has no grader in this build |
| exercises that would **improve** | ~100 more |
| diagrams to draw | ~70 — a class diagram per pattern, the CQRS split, an event-sourced timeline, the CAP triangle |

## Ageing

**None.** GoF is thirty years old and the lesson titles would have been the same twenty years ago. This is the most durable material in the catalogue.

## Flags

**1 ·** **Eighty hours, the largest course in these three categories, and the one that cannot be written until somebody chooses a language.** Nineteen lessons of SOLID, GoF, CQRS, DDD, TDD, functional and reactive programming and the actor model, for a reader holding one of four languages. Three ways out and they cost differently: **pick one language and say so on the first page** (cheapest, and wrong for three quarters of readers); **four snippets per example** (four times the writing and four times the maintenance); **pseudocode** (grades nothing and convinces nobody who came to learn patterns in Go). The sheet does not choose. It records that the choice is upstream of every line of the course and has not been made.

**2 ·** **The content model cannot express any of the three.** Nothing in `content/` varies a course by the track that reached it or by the option a student took at a fork — `backend`'s own note says "the rest of the track is the same on any path", which is a claim about `backend` and not a mechanism. If the answer is four snippets, a section needs to be able to hold four and show one, and that does not exist.

**3 ·** **A quarter of the exercises are blocked, which is the highest proportion the sweep has found outside the vendor courses** — and unlike those, the block is engineering rather than money. A sandbox that runs a student's program unblocks ~200 items here. `git` was the strongest argument for shell first; this is the strongest argument for a language runtime, and it names four.
