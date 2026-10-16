---
title: A working day, and the DELETE in the middle of it
version: 1
---

Lesson 2 repaired a mistake from a dump, and ended on its limit: the dump was older than the
mistake, so every change made between the two was lost or had to be repaired by hand. This lesson
replays the log up to **the moment before the mistake**, and loses nothing written before it.

The setting is lesson 5's: pgBackRest archiving every segment, and one full backup taken at the start
of the day.

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000003

        full backup: 20261010-163600F
            timestamp start/stop: 2026-10-10 16:36:00-03 / 2026-10-10 16:36:03-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000003
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB
```

## The day

Orders arrive, one a second. In the middle of them somebody runs a cleanup that was meant for a
copy of the database, against the real one:

```
ana@vm:~$ for i in 1 2 3 4 5; do psql -q shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1000 + $i, now())"; sleep 1; done
ana@vm:~$ psql shop -c "DELETE FROM orders WHERE placed_at < '2026-03-01'"
DELETE 12059
ana@vm:~$ for i in 6 7 8; do psql -q shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1000 + $i, now())"; sleep 1; done
```

Five orders, the `DELETE`, three more orders. **Twelve thousand and fifty-nine orders from January
and February are gone**, and the eight new ones are real sales that must not be lost in the repair.
That is the shape of almost every point-in-time recovery: one bad transaction with good ones on both
sides of it.

## Noticed

Somebody looks at the shop a few seconds later and sees it:

```
shop=# SELECT count(*), min(placed_at) FROM orders;
 count |          min           
-------+------------------------
 37949 | 2026-03-01 00:00:00-03
(1 row)

shop=# SELECT pg_walfile_name(pg_current_wal_lsn());
     pg_walfile_name      
--------------------------
 000000010000000000000004
(1 row)
```

The oldest order is now from 1 March, and the count is 37949 where it should be 50008. The second
query is the first thing worth asking in an incident like this: **which segment of the log is being
written now**. The mistake happened in the last few seconds, so it is in that segment, `…04`, and
that is where the next section looks for it.

One thing to do at once, before anything else, is nothing that writes. Every transaction from now
on is one more thing that either has to be replayed onto the restored copy or will be lost, and the
fewer there are the simpler the repair.
