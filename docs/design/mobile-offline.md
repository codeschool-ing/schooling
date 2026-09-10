---
format: 5
course: mobile-offline
---

# mobile-offline

**Data on the Device: Offline, Sync and Conflicts** · `co-0jcx9wvc` · 60 h declared · intermediate · 20 lessons · `mobile` · paid

## Reach

In **1 track** — `mobile`(5).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** **nothing declared.** Position 5 of `mobile`, after the fork — so it is written for a student on any of three platforms and names all three.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 20 |
| **hours per lesson** | **3.00** |
| section budget | ~129, about 6.5 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a device or simulator with storage** |
| browser · database | no · **yes, on the device** |
| exercises **blocked** | **~450 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~70 — the sandbox and what backup takes, an outbox draining, delta sync with a cursor, a conflict resolved three ways, a vector clock |

## Ageing

**Low.** Sync, conflict and idempotency are permanent problems; lesson 3 names four databases and lesson 15 names CRDT libraries.

## Flags

**1 ·** **The hardest subject in the mobile track and the one least tied to a platform.** Lessons 7 to 15 — offline-first, the outbox, idempotency keys, delta sync, conflicts, CRDTs — are distributed-systems material that would sit unchanged in `architecture`. **Much of it grades on paper**: "these two writes conflict, which does last-write-wins throw away" is a `quiz`, and "order these sync steps" is an `ordering`.

**2 ·** **Lesson 10 is the example that makes the course matter** — *"Idempotency keys, and the payment that was sent twice"*. Same idea as `pipelines-etl` lesson 15 and `architecture` lesson 7, in three categories, for three audiences. Nobody meets two of them.

**3 ·** **60 hours, 20 lessons, 6.5 sections — the third course in `mobile` with exactly that shape.** See the register.
