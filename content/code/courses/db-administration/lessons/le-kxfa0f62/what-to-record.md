---
title: What to record
version: 1
---

Out of the box the server logs its own life — starting, stopping, checkpoints — and anything at
`WARNING` or worse (`log_min_messages`). That is enough to tell you the server is in trouble and
not enough to tell you why. Five parameters fill the gap, and each one writes a kind of line you
will be glad of on the day something is slow. They take effect on a reload:

```
shop=# ALTER SYSTEM SET log_min_duration_statement = '50ms';
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_temp_files = 0;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

## Slow statements

**`log_min_duration_statement`** writes every statement that took longer than the value, with its
duration. Fifty milliseconds is low, chosen so that the demonstration has something to catch; on a
real server the value is whatever "too slow" means for that application, often a few hundred
milliseconds to a second.

```
shop=# SELECT count(*) FROM orders WHERE status = 'cancelled' AND total_cents > 49000;
 count 
-------
  6000
(1 row)

shop=# SELECT name FROM customers WHERE id = 42;
    name     
-------------
 Customer 42
(1 row)
```

```
ana@db:~$ sudo grep duration: /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:32.075 -03 [234] ana@shop psql LOG:  duration: 81.265 ms  statement: SELECT count(*) FROM orders WHERE status = 'cancelled' AND total_cents > 49000;
```

The count read the whole table and is in the log. The lookup by primary key is not, and **that is
the point of a threshold**: the log holds the statements worth a look and not the millions that
were fine. pg_stat_statements in lesson 18 adds up every statement by shape; this line is the one
occurrence, with its real values, which is what you paste into `EXPLAIN ANALYZE`.

## Sorts that spilled to disk

**`log_temp_files = 0`** writes a line for every temporary file a query had to create, with its
size. A sort or a hash that does not fit in `work_mem` spills, which is lesson 6's subject. Here
`work_mem` is lowered for one session so that a sort of a million values cannot fit:

```
shop=# SET work_mem = '1MB';
SET

shop=# SELECT count(DISTINCT total_cents) FROM orders;
 count 
-------
 50000
(1 row)
```

```
ana@db:~$ sudo grep -A1 'temporary file' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:34.027 -03 [245] ana@shop psql LOG:  temporary file: path "base/pgsql_tmp/pgsql_tmp245.0", size 12050432
2026-10-10 16:44:34.027 -03 [245] ana@shop psql STATEMENT:  SELECT count(DISTINCT total_cents) FROM orders;
```

The `size` is in bytes: about twelve megabytes written and read back for a sort that would have run
in memory with a larger `work_mem`. A value above zero logs only files above that many kilobytes,
which on a busy server keeps out the small ones nobody will act on.

## Lock waits

**`log_lock_waits`** writes a line when a session has waited longer than `deadlock_timeout`, one
second by default, for a lock. Two terminals make one. In the first, a transaction updates a row
and sleeps for four seconds before committing:

```
ana@db:~$ psql shop -c "BEGIN; UPDATE customers SET name = name WHERE id = 1; SELECT pg_sleep(4); COMMIT;"
BEGIN
UPDATE 1
 pg_sleep 
----------
 
(1 row)

COMMIT
```

In the second, while the first is still sleeping, the same row:

```
ana@db:~$ psql shop -c "UPDATE customers SET name = name WHERE id = 1"
UPDATE 1
```

The second `UPDATE` sat silent until the first committed. The log says what it was doing:

```
ana@db:~$ sudo tail -n 9 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:36.801 -03 [258] ana@shop psql LOG:  process 258 still waiting for ShareLock on transaction 782 after 1000.153 ms
2026-10-10 16:44:36.801 -03 [258] ana@shop psql DETAIL:  Process holding the lock: 254. Wait queue: 258.
2026-10-10 16:44:36.801 -03 [258] ana@shop psql CONTEXT:  while updating tuple (0,1) in relation "customers"
2026-10-10 16:44:36.801 -03 [258] ana@shop psql STATEMENT:  UPDATE customers SET name = name WHERE id = 1
2026-10-10 16:44:38.740 -03 [254] ana@shop psql LOG:  duration: 4009.722 ms  statement: BEGIN; UPDATE customers SET name = name WHERE id = 1; SELECT pg_sleep(4); COMMIT;
2026-10-10 16:44:38.740 -03 [258] ana@shop psql LOG:  process 258 acquired ShareLock on transaction 782 after 2939.305 ms
2026-10-10 16:44:38.740 -03 [258] ana@shop psql CONTEXT:  while updating tuple (0,1) in relation "customers"
2026-10-10 16:44:38.740 -03 [258] ana@shop psql STATEMENT:  UPDATE customers SET name = name WHERE id = 1
2026-10-10 16:44:38.741 -03 [258] ana@shop psql LOG:  duration: 2940.940 ms  statement: UPDATE customers SET name = name WHERE id = 1
```

**The `DETAIL` line names the process holding the lock**, and the first terminal's statement is in
the log too, with its four seconds, because it crossed `log_min_duration_statement`. Between them,
that is who blocked whom and with what, written down while it happened. A blocked session that was
cancelled before anyone looked leaves nothing in `pg_stat_activity`; it leaves these lines. Finding
blockers live is db-performance lesson 13.

## Connections

**`log_connections`** and **`log_disconnections`** write a line when a session arrives and when it
ends:

```
shop=# ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@db:~$ psql shop -c "SELECT 1"
 ?column? 
----------
        1
(1 row)

ana@db:~$ sudo grep -E 'connection (received|authenticated|authorized)|disconnection' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:41.991 -03 [99] LOG:  parameter "log_disconnections" changed to "on"
2026-10-10 16:44:42.423 -03 [275] [unknown]@[unknown] [unknown] LOG:  connection received: host=[local]
2026-10-10 16:44:42.423 -03 [275] ana@shop [unknown] LOG:  connection authenticated: identity="ana" method=peer (/etc/postgresql/16/main/pg_hba.conf:123)
2026-10-10 16:44:42.423 -03 [275] ana@shop [unknown] LOG:  connection authorized: user=ana database=shop application_name=psql
2026-10-10 16:44:42.425 -03 [275] ana@shop psql LOG:  disconnection: session time: 0:00:00.002 user=ana database=shop host=[local]
```

Three lines to arrive and one to leave. The `authenticated` line names the method and **the line
of `pg_hba.conf` that matched**, which is the fastest way to answer lesson 5's question of why a
connection was let in or turned away. The `disconnection` line carries the session's length. On a
server whose application opens a connection per request, these two parameters write a line pair
for every request, which is lesson 10's argument for a pool told from the other side.

## Checkpoints, already on

**`log_checkpoints`** is on by default since PostgreSQL 16. A manual `CHECKPOINT` shows the pair
of lines it writes:

```
shop=# CHECKPOINT;
CHECKPOINT
```

```
ana@db:~$ sudo grep checkpoint /var/log/postgresql/postgresql-16-main.log | tail -n 2
2026-10-10 16:44:43.295 -03 [103] LOG:  checkpoint starting: immediate force wait
2026-10-10 16:44:43.529 -03 [103] LOG:  checkpoint complete: wrote 15298 buffers (93.4%); 0 WAL file(s) added, 0 removed, 20 recycled; write=0.114 s, sync=0.113 s, total=0.235 s; sync files=620, longest=0.074 s, average=0.001 s; distance=331117 kB, estimate=331117 kB; lsn=0/1584AD88, redo lsn=0/1584AD50
```

The `[%p]` here is the checkpointer, and `%q` has left its user and database out. Lesson 8 reads
the numbers in the `complete` line. For logging, the useful word is in the `starting` line: the
reason, `immediate force wait` for this manual one, and `time` or `wal` for the ones the server
starts itself. A server that keeps writing `wal` there is checkpointing because it ran out of WAL
room rather than because the clock said so.

## And autovacuum

**`log_autovacuum_min_duration`** is the last of the set. Its default, `600000`, is milliseconds:
an autovacuum run that took longer than ten minutes is logged, which on most servers is none of
them. Lesson 14 lowers it and reads what autovacuum reports.

A reasonable starting set for a production server is therefore: a slow-statement threshold the
application's owners agree on, `log_lock_waits = on`, `log_temp_files` at a few megabytes,
connections on unless the connection rate is very high, and the checkpoints left as they are.
**Every one of these writes lines only when something worth reading happened.** The next section
measures the one parameter that does not work that way.
