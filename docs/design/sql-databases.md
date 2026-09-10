---
format: 5
course: sql-databases
---

# sql-databases

**Relational Databases and SQL** · `co-1y7mkp4n` · 70 h declared · beginner · 13 lessons · `data` · paid

## Reach

In **7 tracks** — `backend`(6), `bi`(5), `data`(8), `data-science`(4), `dba`(5), `qa`(5), `software-architecture`(9).

**Depends on it:** `analytics-bi`, `apis`, `aws-data`, `azure-data`, `data-cleaning`, `data-governance`, `db-administration`, `gcp-data`, `warehouse-modeling`

## Assumes, and leaves ready

**Assumes:** **nothing.** No `requires`, beginner, and it is never position 1 of anything — so it assumes a student who has already paid for something else but knows no SQL.

**Leaves ready:** **more than any other course in the catalogue, jointly with `python`.** Nine courses require it by name — `analytics-bi`, `apis`, the three vendor data courses, `data-cleaning`, `data-governance`, `db-administration` and `warehouse-modeling` — across seven tracks. What it leaves ready is the relational model itself: keys, joins, aggregation, transactions, indexes and a plan.

## Shape

| | |
|---|---|
| declared hours | 70 h |
| lessons | 13 |
| **hours per lesson** | **5.38** |
| section budget | ~150, about 11.5 a lesson |
| exercises | ~700, at the catalogue's density |

## Execution

| | |
|---|---|
| runtime | **a database the student can query and change** |
| browser · database | no · **yes, and this is the cheap end of the category** — a schema per student on one server, or a Postgres compiled to WebAssembly running in the tab |
| exercises **blocked** | **~450 (60%) — the highest proportion in the sweep so far.** SQL is a language you learn by running |
| exercises that would **improve** | the rest |
| diagrams to draw | ~45 — a schema, each join drawn as sets, a B-tree, an execution plan read line by line |

## Ageing

**None.** The relational model is older than everybody who will teach it, and lesson 13 on Oracle is the only one naming a vendor.

## Flags

**1 ·** **The highest-leverage unbuilt environment in the catalogue, and it may be the cheapest.** Nine dependents and seven tracks wait behind a database, and unlike every environment `infra` asked for — a container daemon, a cluster, a topology, a hypervisor — this one has a version that runs **in the browser with no server at all**: SQLite or Postgres compiled to WebAssembly, seeded from a fixture, thrown away on reload. `expected-output` has no grader today, but a query's result set is a table, and comparing two tables is not a sandbox.

That is the `infra` sweep's "a topology is the cheapest environment and serves four courses" argument, one order of magnitude larger: **the cheapest environment in the catalogue, serving the most dependents in it.** If one thing in the whole sweep is built first, the evidence points here.

**2 ·** **Beginner, 70 hours, thirteen lessons — 11.5 sections a lesson, among the widest in the catalogue.** Lesson 6 alone is aggregation, `GROUP BY`, `HAVING` and window functions. These are not lessons in the sense `first-job` uses the word, and the section design has to give each an internal arc.

**3 ·** **It ties `python` at nine dependents, and the two of them are the catalogue's spine.** Neither is free anywhere. Whatever is decided about the free tier, these are the two courses whose quality propagates furthest — and a defect here is a defect in seven tracks.
