---
format: 5
course: db-administration
---

# db-administration

**Database Server: Installation and Maintenance** · `co-xk5sga5s` · 70 h declared · intermediate · 24 lessons · `data` · paid

## Reach

In **1 track** — `dba`(6).

**Depends on it:** `db-performance`, `db-reliability`, `nosql-operations`

## Assumes, and leaves ready

**Assumes:** `sql-databases` and `linux-terminal` — SQL, and a shell to run the server from. The only course in the category requiring both, and it needs both.

**Leaves ready:** the operating vocabulary its three dependents stand on: `db-performance`, `db-reliability` and `nosql-operations`. **The only three-dependent course in `data` besides the two hubs.**

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
| runtime | **a database server the student owns, on a machine they can misconfigure** |
| browser · database | no · **yes, and not the query surface — the process, its files, its memory and its logs** |
| exercises **blocked** | **~500 (70%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~60 — the data directory, the write-ahead log through a checkpoint, a bloated table, a lock graph |

## Ageing

**Low.** Lesson 2 names four engines and the rest is PostgreSQL-shaped; the concepts outlive the version numbers.

## Flags

**1 ·** **A database a student can query is not a database a student can administer**, and this is where the category's environment splits in two. `sql-databases` needs a query surface, which a browser can hold. This needs a **server with a data directory, a configuration file, a log and enough privilege to break it** — lesson 5 is the configuration file, lesson 14 is autovacuum falling behind, lesson 22 changes the schema of a live table. None of that is expressible against a shared instance.

**2 ·** **It gates a third of its track.** `dba` reaches it at position 6, and positions 7, 8 and 11 are its dependents. **210 further hours sit behind this one environment**, which is the highest concentration of blocked hours behind a single unbuilt thing that the sweep has found.

**3 ·** **Twenty-four lessons that are one job.** Unlike `sql-databases`'s thirteen wide lessons, these are narrow and sequential — 6.2 sections each — and they read as a runbook in the order somebody learns it. Lesson 24 is literally *"The runbook: writing down what you did at three in the morning"*. The section design should follow that shape rather than impose an arc on it.
