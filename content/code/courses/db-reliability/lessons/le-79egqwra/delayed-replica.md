---
title: A replica that is behind on purpose
version: 1
---

Every standby so far copies a mistake as faithfully as everything else; lesson 11 called that the
replicated `DELETE`. A **delayed replica** keeps a window open: `recovery_min_apply_delay` makes it
receive the log at once and apply each transaction only after the delay has passed. Two minutes here,
so that the lesson does not wait long; an hour or more in practice. Set it on `standby1`:

```
ana@vm:~$ sudo -u postgres psql -p 5434 -c "ALTER SYSTEM SET recovery_min_apply_delay = '2min'" -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)
```

Now the mistake: an order clean-up meant for one customer's test orders runs against customer 7's real
ones on the primary. Seconds later, count customer 7's orders on both standbys:

```
shop=# SELECT now();
              now              
-------------------------------
 2026-10-16 02:32:18.565434-03
(1 row)

shop=# DELETE FROM orders WHERE customer_id = 7;
DELETE 50
shop=# SELECT count(*) FROM orders WHERE customer_id = 7;
 count 
-------
    50
(1 row)
shop=# SELECT count(*) FROM orders WHERE customer_id = 7;
 count 
-------
     0
(1 row)
```

On `standby1` the **50 orders are still there**; the delete is in its `pg_wal`, waiting for two
minutes to pass. On `standby2` they are **gone**: a cascade forwards the log as it arrives, and
`standby2` has no delay of its own. A delayed replica protects only itself, and anything that needs
the delay must hang from the primary or have the setting itself.

Pause the delayed replica's replay before the two minutes run out, copy the 50 rows out of it, and copy
them back into the primary:

```
shop=# SELECT pg_wal_replay_pause();
 pg_wal_replay_pause 
---------------------
 
(1 row)
ana@vm:~$ psql -p 5434 shop -c "\copy (SELECT * FROM orders WHERE customer_id = 7) TO 'orders-7.csv' CSV"
COPY 50
ana@vm:~$ psql shop -c "\copy orders FROM 'orders-7.csv' CSV"
COPY 50
ana@vm:~$ psql -XAt shop -c "SELECT count(*) FROM orders WHERE customer_id = 7"
50
shop=# SELECT pg_wal_replay_resume();
 pg_wal_replay_resume 
----------------------
 
(1 row)
```

Fifty orders back on the primary, with their original ids, two minutes after they were deleted, and
without a restore. `\copy` is `psql` reading or writing a file on your side of the connection; `COPY`
into a table with an identity column keeps the ids it is given. Resuming replay lets `standby1` apply the
delete and then the reinsert, and arrive at the same rows as the primary.

## What it costs, and what it does not cover

- The delayed replica is **useless for failover**: promoting it means waiting the whole delay for it to
  catch up, or giving up the last hour. It is a third standby, not one of the two.
- It holds an hour of log, on its disk and, through its slot, on the primary's.
- It covers a mistake noticed **within the delay**. One noticed tomorrow needs lesson 6's
  point-in-time recovery from the archive, which is still the backstop under everything.
