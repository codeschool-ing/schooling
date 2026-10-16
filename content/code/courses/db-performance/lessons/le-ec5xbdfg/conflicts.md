---
title: The query the replica cancels, and the price of keeping it
version: 1
---

A replica looks like a place to send the long reads: the report that scans a year, the export that
runs for ten minutes. They are reads, they would take a processor from the primary, and the replica
has processors to spare. Then the report fails halfway with an error nobody has seen before, and it
fails more often the busier the primary is. The belief to correct is that a replica only ever
receives changes. **It also has to apply them while your query is reading**, and sometimes the two
cannot both happen.

## Why replay and a query collide

Lesson 15 showed that `VACUUM` removes row versions no transaction can still see, and that a long
transaction holds them back. On the primary, `VACUUM` knows every transaction, so it never removes a
row somebody is reading. It does **not** know about queries running on a replica. It removes the
rows, the removal is in the WAL, and the replica has to replay it while one of its own queries may
still need those rows.

The replica has two choices: pause replay until the query finishes, falling further behind, or
cancel the query. It pauses for at most **`max_standby_streaming_delay`**, 30 seconds by default,
and then cancels. Shorten it to 5 seconds on the replica and take off last section's delay. Then set up the
collision with two sessions at once: on the replica, a transaction that reads the oldest events
and then stays open; on the primary, three seconds later, a `DELETE` of those events and a `VACUUM`.
First the settings, in
`psql -p 5433 market` on the replica:

```
market=# ALTER SYSTEM RESET recovery_min_apply_delay;
ALTER SYSTEM
Time: 4.574 ms

market=# ALTER SYSTEM SET max_standby_streaming_delay = '5s';
ALTER SYSTEM
Time: 2.147 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.723 ms
```

Session A, on the replica:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.357 ms

market=*# SELECT count(*) FROM events WHERE at < '2025-10-04';
 count 
-------
 55284
(1 row)

Time: 172.093 ms

market=*# SELECT pg_sleep(30);
ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
Time: 8991.526 ms (00:08.992)

market=!# ROLLBACK;
ROLLBACK
Time: 0.258 ms
```

Session B, on the primary, started three seconds after A:

```
market=# DELETE FROM events WHERE at < '2025-10-04';
DELETE 55284
Time: 638.095 ms

market=# VACUUM events;
VACUUM
Time: 5.152 ms
```

The primary deleted **55284** events and vacuumed them away in 5 milliseconds, with no idea that
anybody still wanted them. The replica's transaction, a `REPEATABLE READ` whose snapshot still
includes those rows, was cancelled **8992 milliseconds** into its sleep. That is three seconds of
waiting for B, about one for the `DELETE`, and the five the replica allowed replay to wait:
**`canceling statement due to conflict with recovery`**, `User query might have needed to see row
versions that must be removed`. The transaction is left aborted, `market=!#`, and the replica's log
records each one:

```
ana@vm:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-replica.log
2026-10-10 22:51:07.770 -03 [3619] ana@market ERROR:  canceling statement due to conflict with recovery
2026-10-10 22:51:07.770 -03 [3619] ana@market DETAIL:  User query might have needed to see row versions that must be removed.
2026-10-10 22:51:07.770 -03 [3619] ana@market STATEMENT:  SELECT pg_sleep(30);
```

These lines are the thing to look for when reports on a replica fail at random. The view
`pg_stat_database_conflicts` on the replica counts them per database and per kind; this kind is
`confl_snapshot`. Removed rows are the commonest cause, and not the only one: a `DROP TABLE`, or
anything else that takes an `ACCESS EXCLUSIVE` lock on the primary, conflicts with every query on
that table on the replica in the same way.

## Keeping the query, and what it costs the primary

**`hot_standby_feedback`** makes the replica tell the primary which rows its queries still need,
and the primary's `VACUUM` then leaves them alone. Turn it on, on the replica, and repeat the
collision with the next day of events:

```
market=# ALTER SYSTEM SET hot_standby_feedback = on;
ALTER SYSTEM
Time: 2.541 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.663 ms
```

Session A, on the replica:

```
market=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN
Time: 0.256 ms

market=*# SELECT count(*) FROM events WHERE at < '2025-10-05';
 count 
-------
 55395
(1 row)

Time: 214.634 ms

market=*# SELECT pg_sleep(15);
 pg_sleep 
----------
 
(1 row)

Time: 15015.869 ms (00:15.016)

market=*# ROLLBACK;
ROLLBACK
Time: 0.227 ms
```

Session B, on the primary:

```
market=# DELETE FROM events WHERE at < '2025-10-05';
DELETE 55395
Time: 473.174 ms

market=# VACUUM (VERBOSE) events;
INFO:  vacuuming "market.public.events"
INFO:  finished vacuuming "market.public.events": index scans: 0
pages: 0 removed, 65432 remain, 1450 scanned (2.22% of total)
tuples: 0 removed, 4944521 remain, 55395 are dead but not yet removable
removable cutoff: 1579487, which was 1 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan bypassed: 724 pages from table (1.11% of total) have 55284 dead item identifiers
avg read rate: 0.000 MB/s, avg write rate: 0.000 MB/s
buffer usage: 2216 hits, 0 misses, 0 dirtied
WAL usage: 1 records, 0 full page images, 188 bytes
system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
```

The replica's sleep ran its full **15 seconds** and the transaction ended normally. On the primary,
`VACUUM (VERBOSE)` says why: **`55395 are dead but not yet removable`**, and `0 removed`. The rows
the replica's snapshot needed are still in the table, because the replica asked for them. After this
report the same output repeats for `events`' TOAST table, with nothing in it, and ends with
`VACUUM`.

So the conflict did not disappear. It moved. Without feedback, the replica cancels its own queries.
With it, a long query on the replica holds back `VACUUM` **on the primary**, exactly as a long
transaction on the primary does in lesson 15. Dead rows pile up in the tables the primary is
writing, the tables and their indexes swell, and every query that reads them pays. A replica built
to take load off the primary can, through one setting and one forgotten report, make the primary
slower.

## Choosing

There is no setting that gives both, so choose by what the replica is for:

| the replica serves | set | and accept |
|---|---|---|
| short reads: pages, searches, dashboards | defaults: `hot_standby_feedback` off, 30 s delay | an occasional cancelled query, which the application retries |
| long reports that must finish | `hot_standby_feedback` on | bloat on the primary while they run; watch for it |
| reports, and a replica that may become the primary | a separate replica for each job | one more server |

A replica that also stands ready for failover should not be the one running hour-long reports,
whichever way it is set: with feedback it bloats the primary, and with a long
`max_standby_streaming_delay` it falls behind, which is the worst moment to promote it.
`db-reliability` lesson 15 is about that choice.

## Putting the machine back

The replica is a whole second server with a copy of every database: remove it when you are done.
`pg_dropcluster` stops it and deletes its data directory and its configuration:

```
ana@vm:~$ sudo pg_dropcluster 16 replica --stop
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

One cluster again. The primary's settings are untouched, since every change in this lesson was
made with `ALTER SYSTEM` on the replica, which went with it. The rows are not: the two `DELETE`s
removed the first two days of `events`, two orders were cancelled, and the purchase runs added
some forty thousand orders. Close `psql` and run
`~/reset-market.sh` before lesson 21.
