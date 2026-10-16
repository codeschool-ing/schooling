---
title: Why a schema change can stop a system
version: 1
---

A system that scales is changed often, and a change of code usually comes with a change of schema:
a new column, a new index, a constraint, a wider type. On a small table these are instant and nobody
thinks about them. **On a table that is large and busy, the same statement can stop every write to
it for seconds or minutes**, and the cause is rarely the statement's own work.

Two things make a schema change dangerous, and this lesson measures both on the box office.

**The lock it needs.** PostgreSQL protects a table's structure with locks of different strengths.
An ordinary `SELECT` takes the weakest, `ACCESS SHARE`; an `INSERT` takes `ROW EXCLUSIVE`; neither
blocks the other. Most `ALTER TABLE` forms take the strongest, **`ACCESS EXCLUSIVE`**, which
conflicts with everything, reads included, because the table's shape is about to change under them.
Holding it for a millisecond is harmless. **Waiting for it** is not, as section 03 shows.

**The work it does while holding it.** Some changes only edit the catalogue and finish in
milliseconds. Others rewrite every row of the table, or scan all of it, while the lock is held, and
on a table of millions of rows that takes seconds or minutes. Section 05 sorts the common changes
into the two groups.

| | takes | blocks |
|---|---|---|
| `SELECT` | `ACCESS SHARE` | only `ACCESS EXCLUSIVE` |
| `INSERT`, `UPDATE`, `DELETE` | `ROW EXCLUSIVE` | `SHARE` and stronger, `ACCESS EXCLUSIVE` included |
| `CREATE INDEX` | `SHARE` | writes |
| `CREATE INDEX CONCURRENTLY`, `VALIDATE CONSTRAINT` | `SHARE UPDATE EXCLUSIVE` | other schema changes, not reads or writes |
| most `ALTER TABLE`, `DROP TABLE` | `ACCESS EXCLUSIVE` | everything |

The table is a short version of the one in PostgreSQL's documentation, which lists every statement
and every pair of conflicting locks, and it is worth reading once.

## A table worth changing

The box office's `tickets` table holds a handful of rows from earlier lessons. To make its changes
take measurable time, give it two million tickets, which is about what a busy ticket seller writes
in a few weeks:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'INSERT INTO tickets (event_id, seat, code) SELECT 1 + n % 100, 1000000 + n, md5(n::text) FROM generate_series(1, 2000000) AS n'
INSERT 0 2000000
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_size_pretty(pg_total_relation_size('tickets'))"
 pg_size_pretty 
----------------
 276 MB
(1 row)
```

276 MB, with its indexes. Keep the stack running for the rest of the lesson; every section changes
this same table.
