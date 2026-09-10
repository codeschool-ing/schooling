---
format: 5
course: data-governance
---

# data-governance

**Data Security, Governance and Privacy** · `co-mc9rrv3c` · 60 h declared · intermediate · 11 lessons · `data` · paid

## Reach

In **2 tracks** — `bi`(14), `data-platform`(5).

**Depends on it:** **nothing**

## Assumes, and leaves ready

**Assumes:** `sql-databases` — the tables the access control is over.

**Leaves ready:** **nothing.** No course requires it.

## Shape

| | |
|---|---|
| declared hours | 60 h |
| lessons | 11 |
| **hours per lesson** | **5.45** |
| section budget | ~129, about 11.7 a lesson |
| exercises | ~610, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a database with roles**, and a key-management service for lessons 3 and 4 |
| browser · database | no · **yes** |
| exercises **blocked** | **~250 (40%)** |
| exercises that would **improve** | ~150 |
| diagrams to draw | ~60 — row and column policies, an encryption boundary, a lineage graph, a retention timeline, the LGPD legal bases as a decision tree |

## Ageing

**Moderate, and legally.** Lesson 8 is GDPR and the EU AI Act — the AI Act is phasing in now, so this is the one course in the catalogue whose material can be made wrong by a legislature rather than by a vendor.

## Flags

**1 ·** **The only course whose ageing is statutory**, and it needs a review cadence for that reason rather than for a product's. `first-job` ages on a market's schedule and this one on a parliament's; between them they are the two courses where "still accurate" is not something the author controls.

**2 ·** **This platform has already done the exercise, and the artefacts are in this repository.** `internal/privacy` is a registry naming every table, what personal data it holds, whose it is, and what erasure does to it — with a test comparing it against the live schema. That is lesson 6, lesson 9 and lesson 10 as working code. **The most direct case in the sweep of the platform being able to teach from itself**, and it costs nothing to use.

**3 ·** **Eleven lessons for sixty hours — 11.7 sections each.** Lesson 7 is the whole of the LGPD. Wide lessons again, and here the width is legal text that has to be made teachable rather than summarised.
