---
format: 5
course: go-production
---

# go-production

**Go in Production: CLIs, Tooling and Performance** · `co-k6k0fw16` · 70 h declared · advanced · 24 lessons · `backend` · paid

## Reach

In **1 track** — `backend`(5, choice *Go*).

**Reached through a choice**, never in sequence — so **no course after that fork may assume it was taken**.

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `go-concurrency` — a sibling of `go-back` rather than a successor, so it may assume no web experience.

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
| runtime | **the Go toolchain, plus pprof and trace** |
| browser · database | no · no |
| exercises **blocked** | **~500 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~55 — a flame graph read twice, escape analysis drawn, stack against heap, the scheduler in a trace |

## Ageing

**Low.**

## Flags

**1 ·** **Lessons 12 to 14 are the most valuable in the Go path and the hardest to teach without a machine.** pprof, reading a profile, and `trace`. A profile is a picture, so **`labelling` on a real flame graph grades today** — "mark the call that costs most in total, not per run" — which is the same trick `db-performance` needs for `EXPLAIN`.

**2 ·** **Lessons 21 to 24 are the escape hatches** — reflection, `unsafe`, CGO, plugins — and each is taught with its cost. That is the right treatment and it is the part a reader skims. Worth weighting the material against the instinct.

**3 ·** **The fourth course of a 290-hour path that nothing else in the catalogue requires**, in one track, behind one fork option. Valuable and last in any sensible order.
