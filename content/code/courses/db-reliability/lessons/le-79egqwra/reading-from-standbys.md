---
title: Reads on a standby, and the query that gets cancelled
version: 1
---

A standby answers queries, so reports, searches and exports can move there and leave the primary to
take writes; lesson 19's port 5001 spread exactly those. There is a conflict built into it. The
primary's `VACUUM` removes old versions of rows once **no query on the primary** can still need them,
and the standby replays that removal. A long query on the standby may still need them.

Start a report on `standby2`: a transaction that counts the orders, waits a minute, and counts again
from the same snapshot. While it waits, the primary updates a thousand orders and vacuums:

```
ana@vm:~$ psql -p 5435 shop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT count(*) FROM orders' -c 'SELECT pg_sleep(60)' -c 'SELECT count(*) FROM orders' -c 'COMMIT' > report.log 2>&1 &
shop=# UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000;
UPDATE 1000

shop=# VACUUM orders;
VACUUM
ana@vm:~$ cat report.log
BEGIN
 count 
-------
 50000
(1 row)

ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK
```

The second count never ran: **`canceling statement due to conflict with recovery`**. The standby
waited `max_standby_streaming_delay`, 30 seconds by default, with the replay held back for the report's
sake, then cancelled the report so that replay could go on. A standby has to choose between being
current and letting a query finish, and by default it chooses being current after thirty seconds.

## Feedback

`hot_standby_feedback` makes the other choice: the standby tells its upstream which rows its queries
still need, and the primary's `VACUUM` keeps them. On a cascade it has to be on at every step, so that
`standby1` passes `standby2`'s request on:

```
ana@vm:~$ sudo -u postgres psql -p 5435 -c 'ALTER SYSTEM SET hot_standby_feedback = on' -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~$ sudo -u postgres psql -p 5434 -c 'ALTER SYSTEM SET hot_standby_feedback = on' -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~$ psql -p 5435 shop -c 'BEGIN ISOLATION LEVEL REPEATABLE READ' -c 'SELECT count(*) FROM orders' -c 'SELECT pg_sleep(45)' -c 'SELECT count(*) FROM orders' -c 'COMMIT' > report.log 2>&1 &
shop=# SELECT slot_name, xmin FROM pg_replication_slots;
 slot_name | xmin 
-----------+------
 standby1  |  739
(1 row)

shop=# UPDATE orders SET total_cents = total_cents + 1 WHERE id <= 1000;
UPDATE 1000

shop=# VACUUM orders;
VACUUM

shop=# SELECT n_dead_tup FROM pg_stat_user_tables WHERE relname = 'orders';
 n_dead_tup 
------------
       1000
(1 row)
ana@vm:~$ cat report.log
BEGIN
 count 
-------
 50000
(1 row)

 pg_sleep 
----------
 
(1 row)

 count 
-------
 50000
(1 row)

COMMIT
```

The slot `standby1` now carries an `xmin`, the oldest transaction a query downstream still needs.
After the same `UPDATE` and `VACUUM`, the primary reports **1000 dead row versions it did not
remove**, and the report finished both counts.

That is the price, moved to the primary: **a long query on any standby holds back cleanup on the
primary** for as long as it runs. A report that runs for six hours on a reporting standby is six hours
of dead rows piling up in the primary's busiest tables. Feedback is right for short queries that must
not be cancelled; for long reports, a standby kept apart without feedback, with a large
`max_standby_streaming_delay`, falls behind instead of bloating the primary.
