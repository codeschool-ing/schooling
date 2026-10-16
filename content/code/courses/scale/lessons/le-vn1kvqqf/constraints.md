---
title: Constraints without a long lock
version: 1
---

Every ticket now has a gate, and the schema should say so: `gate` should be `NOT NULL`, so that a
future bug that forgets it is refused by the database instead of stored. `ALTER COLUMN gate SET NOT
NULL` does that, and it has to check that no existing row is `NULL` first: a **scan of the whole
table under `ACCESS EXCLUSIVE`**, which on two million rows is the same kind of stall as section 05.

PostgreSQL offers a way round it in two steps.

**First, add the rule without checking the past.** A `CHECK` constraint added `NOT VALID` is
enforced on every new and updated row from that moment, and **existing rows are not checked**, so it
needs its lock for an instant only.

**Then validate it.** `VALIDATE CONSTRAINT` scans the table to prove the old rows obey the rule, but
it takes the weaker `SHARE UPDATE EXCLUSIVE` lock, so reads and writes carry on while it scans.

And from PostgreSQL 12, **`SET NOT NULL` skips its scan when a valid `CHECK (col IS NOT NULL)`
already proves it**. The three steps, timed, with sales running during the validation:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD CONSTRAINT gate_set CHECK (gate IS NOT NULL) NOT VALID'
Timing is on.
ALTER TABLE
Time: 2.388 ms
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets VALIDATE CONSTRAINT gate_set'
Timing is on.
ALTER TABLE
Time: 258.539 ms
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1186 in 8.0 s = 147.4 per second
latency   p50 12.4 ms  p95 74.7 ms  p99 80.3 ms  max 84.8 ms
status    201: 1186
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ALTER COLUMN gate SET NOT NULL'
Timing is on.
ALTER TABLE
Time: 1100.553 ms (00:01.101)
ana@lab:~/tickets$ docker compose logs db | grep 'canceling autovacuum'
db-1  | 2026-10-10 05:50:23.909 UTC [786] ERROR:  canceling autovacuum task
```

- `ADD CONSTRAINT … NOT VALID` took **2.4 ms**: catalogue only, for an instant of `ACCESS EXCLUSIVE`.
- `VALIDATE CONSTRAINT` scanned the table in **259 ms**, and the sales alongside it, **1186 with a
  worst case of 85 ms**, did not feel it.
- `SET NOT NULL` found the valid constraint and did not scan, and still took **1.1 seconds**, for a
  reason that is not its own work. The last command explains it: PostgreSQL's **autovacuum** was
  cleaning the table after the backfill, holding a lock that conflicts with `ACCESS EXCLUSIVE`. When
  an autovacuum blocks someone for longer than `deadlock_timeout`, one second by default, PostgreSQL
  cancels it and logs `canceling autovacuum task`, and that second is the time the change waited.
  With `lock_timeout` set as in section 04, a wait like that stays bounded whatever causes it.

The same pattern works for foreign keys: `ADD CONSTRAINT … FOREIGN KEY … NOT VALID`, then `VALIDATE
CONSTRAINT`. Once `gate` is `NOT NULL`, the `CHECK` is redundant and can be dropped, which is
instant.
