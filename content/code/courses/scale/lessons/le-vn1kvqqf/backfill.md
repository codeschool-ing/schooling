---
title: Backfilling in batches
version: 1
---

The new column `gate` exists, and new tickets get a value. Two million old ones have `NULL`, and
they have to be filled before the column can be required. The obvious statement is one `UPDATE`:

```sql
UPDATE tickets SET gate = CASE WHEN id % 2 = 0 THEN 'A' ELSE 'B' END WHERE gate IS NULL;
```

It works, and it is the wrong way on a busy table, for three reasons that grow with the table:

- **It is one transaction.** Every row it updates stays locked until it commits, so any other write
  to those rows waits for the whole run.
- **Its log is one burst.** Every updated row is a new row version in the WAL, sent to every
  replica at once, so the replicas of lesson 2 fall behind for as long as they take to apply it.
- **It cannot be paused or resumed.** Stopped half-way, it rolls everything back, and the work is
  lost.

## A procedure that commits as it goes

A **procedure** in PostgreSQL can commit in the middle of its work, which a single statement cannot.
This one walks the table by `id` in ranges of `batch` rows, updates the rows of each range that
still have no gate, commits, pauses twenty milliseconds so that other work gets a turn, and moves
on. Save it as `backfill.sql`:

```sql
-- backfill.sql
CREATE OR REPLACE PROCEDURE backfill_gate(batch int) LANGUAGE plpgsql AS $$
DECLARE
  lo   bigint := 0;
  last bigint;
BEGIN
  SELECT max(id) INTO last FROM tickets;
  WHILE lo < last LOOP
    UPDATE tickets SET gate = CASE WHEN id % 2 = 0 THEN 'A' ELSE 'B' END
    WHERE id > lo AND id <= lo + batch AND gate IS NULL;
    lo := lo + batch;
    COMMIT;
    PERFORM pg_sleep(0.02);
  END LOOP;
END
$$;
```

`CREATE OR REPLACE PROCEDURE` only defines it. First the default for new rows, then the procedure,
then a run with batches of 50 000 rows and, in another terminal, fifteen seconds of sales:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "ALTER TABLE tickets ALTER COLUMN gate SET DEFAULT 'A'"
ALTER TABLE
ana@lab:~/tickets$ docker compose cp backfill.sql db:/tmp/backfill.sql
 tickets-db-1 Copying backfill.sql to tickets-db-1:/tmp/backfill.sql
 tickets-db-1 Copied backfill.sql to tickets-db-1:/tmp/backfill.sql
ana@lab:~/tickets$ docker compose exec db psql -U tickets -f /tmp/backfill.sql
CREATE PROCEDURE
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'CALL backfill_gate(50000)'
Timing is on.
CALL
Time: 53493.510 ms (00:53.494)
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 15 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  2132 in 15.1 s = 141.6 per second
latency   p50 19.1 ms  p95 64.6 ms  p99 112.4 ms  max 334.6 ms
status    201: 2132
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'SELECT gate, count(*) FROM tickets GROUP BY gate ORDER BY gate'
 gate |  count  
------+---------
 A    | 1003569
 B    | 1001437
(2 rows)
```

The backfill took **53.5 seconds**, and the box office barely noticed: **2132 sales in fifteen
seconds, 141.6 a second, worst case 335 ms**, close to its normal rate on one processor. Each batch
held its row locks for a fraction of a second and wrote a modest piece of log, and the pauses let
the sales and the replica keep up.

The final count has no `NULL` group: the old rows got `A` or `B`, and the sales made during and
after the backfill got `A` from the default.

## Tuning a backfill

The batch size and the pause are the two dials, and both are measured rather than guessed:

- **a bigger batch** finishes sooner and holds each lock longer;
- **a longer pause** protects the rest of the system and stretches the total time;
- **the order should follow an index**, here the primary key, so that each batch finds its rows
  without scanning, and a batch that is interrupted can be resumed from the last `id` it reached.

Watch the replica's `replay_lag` from lesson 2 while it runs. If it grows, the pause is too short.
