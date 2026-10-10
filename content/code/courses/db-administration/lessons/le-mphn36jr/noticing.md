---
title: Noticing, and tuning one table
version: 1
---

Autovacuum does its work quietly, and on PostgreSQL 16 it also reports it quietly. Three places
tell you what it did, and **the first is a query worth keeping**:

```
shop=# SELECT relname, n_live_tup, n_dead_tup, last_vacuum, last_autovacuum FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;
   relname   | n_live_tup | n_dead_tup |          last_vacuum          |        last_autovacuum        
-------------+------------+------------+-------------------------------+-------------------------------
 customers   |      50000 |          0 |                               | 2026-10-10 16:40:43.441353-03
 orders_copy |    1000000 |          0 | 2026-10-10 16:42:53.500473-03 | 2026-10-10 16:42:43.904485-03
 orders      |    1000000 |          0 |                               | 2026-10-10 16:40:43.699616-03
(3 rows)
```

A table near the top with a large `n_dead_tup` and an old or empty `last_autovacuum` is one
autovacuum has not reached or cannot clean. The previous sections give the two usual reasons: its
line is too high for its size, or something holds the horizon. `orders_copy` has a `last_vacuum`
as well, from the `VACUUM` typed by hand in the falling-behind section; the `auto` columns are the
ones that say whether the server is keeping up by itself.

**The second is the log**, and by default it says almost nothing:

```
shop=# SHOW log_autovacuum_min_duration;
 log_autovacuum_min_duration 
-----------------------------
 10min
(1 row)
```

Only an autovacuum that takes ten minutes or more is logged. That catches the run that matters on a
large table and none of the ones that would show you its rhythm. Lesson 19 sets the logging for the
whole server. Here the setting goes on one table, together with the fix the trigger section
promised for large tables: a scale factor of 1% instead of 20%.

```
shop=# ALTER TABLE orders_copy SET (autovacuum_vacuum_scale_factor = 0.01, log_autovacuum_min_duration = 0);
ALTER TABLE

shop=# SELECT relname, reloptions FROM pg_class WHERE relname = 'orders_copy';
   relname   |                             reloptions                              
-------------+---------------------------------------------------------------------
 orders_copy | {autovacuum_vacuum_scale_factor=0.01,log_autovacuum_min_duration=0}
(1 row)

shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 20000;
UPDATE 20000
```

`reloptions` is where per-table settings live, and `\d+ orders_copy` prints them as well, under
`Options:`. The line for this table is now 50 plus 1% of a million, 10,050 dead versions, so 20,000
is over it. On the launcher's next round:

```
ana@db:~$ sudo grep -A10 'automatic vacuum of table "shop.public.orders_copy"' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:43.517 -03 [973] LOG:  automatic vacuum of table "shop.public.orders_copy": index scans: 0
	pages: 0 removed, 10417 remain, 338 scanned (3.24% of total)
	tuples: 20000 removed, 987756 remain, 0 are dead but not yet removable
	removable cutoff: 809, which was 0 XIDs old when operation ended
	frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
	index scan bypassed: 167 pages from table (1.60% of total) have 19957 dead item identifiers
	avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
	buffer usage: 557 hits, 0 misses, 0 dirtied
	WAL usage: 342 records, 0 full page images, 59812 bytes
	system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
```

Every line is one you met in `VACUUM VERBOSE`, written by the worker into the server's log with a
timestamp. **`20000 removed` and `0 are dead but not yet removable` is the healthy shape.**
`index scan bypassed` is an economy added in version 14: when fewer than 2% of the table's pages have dead
entries, the worker leaves the indexes for a later pass rather than reading all of them for so
little.

The third place is `pg_stat_progress_vacuum`, which has a row for every VACUUM running at that
moment, with the phase it is in and how many pages it has read. It is the view to open when
something has been vacuuming for an hour and you want to know whether it is nearly done.

**Per-table settings are how autovacuum is tuned in practice.** The server-wide defaults suit most
tables; the few large, busy ones get their own scale factor or threshold. Never answer a problem
with `autovacuum_enabled = false` on a table. It stops the ordinary visits and leaves only the
aggressive one, the wraparound section's, which arrives later and larger.

## Putting shop back

The copy and the two extensions were for this lesson. Remove them, and `shop` is as lesson 4 left
it:

```
shop=# DROP TABLE orders_copy;
DROP TABLE

shop=# DROP EXTENSION pageinspect;
DROP EXTENSION

shop=# DROP EXTENSION pg_visibility;
DROP EXTENSION
```
