---
title: The stale read, and reading your own writes
version: 1
---

A standby answers queries, which is half of its appeal: reports and searches go there and leave the
primary to the writes. The price is that **every read on a standby is from the past**, by however far
it is behind. A standby can be held still on purpose with `pg_wal_replay_pause()`, which is how this
section makes the past last long enough to look at. Pause it, let the primary write, and place an
order:

```
shop=# SELECT pg_wal_replay_pause();
 pg_wal_replay_pause 
---------------------
 
(1 row)
ana@vm:~$ pgbench -c 4 -T 10 -n bench > /dev/null 2>&1
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (31, 3100, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1
shop=# SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;
 application_name | behind  |    write_lag    |    flush_lag    |   replay_lag    
------------------+---------+-----------------+-----------------+-----------------
 standby1         | 9967 kB | 00:00:00.000416 | 00:00:00.000733 | 00:00:10.372016
(1 row)
shop=# SELECT count(*) FROM orders WHERE customer_id = 31 AND total_cents = 3100;
 count 
-------
     0
(1 row)
```

The standby received the log (`write_lag` and `flush_lag` are still under a millisecond) and did not
apply it: 9967 kB behind and `replay_lag` above ten seconds, growing for as long as the pause lasts.
And the order, `50001`, **is not there**. A customer who places an order and is taken to a page that
reads from the standby sees no order, and places it again.

## Reading your own writes

The fix most applications use is the simplest: **after a write, read from the primary** for a while,
or for the rest of that request. Another is lesson 12's `remote_apply`, which makes the commit wait
until the standby has replayed it, so any read after the commit sees it, at a price on every commit.

The precise one is to compare positions. After its write, the application asks the primary where the
log is; before reading from the standby, it asks the standby whether it has replayed that far:

```
ana@vm:~$ lsn=$(psql -XAt shop -c "SELECT pg_current_wal_lsn()")
ana@vm:~$ echo $lsn
0/FFF3378
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT pg_last_wal_replay_lsn() >= '$lsn'"
f
```

`f`: the standby is not there yet, so this read goes to the primary, or waits. Resume replay and ask
again:

```
shop=# SELECT pg_wal_replay_resume();
 pg_wal_replay_resume 
----------------------
 
(1 row)
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT pg_last_wal_replay_lsn() >= '$(psql -XAt shop -c 'SELECT pg_current_wal_lsn()')'"
t
ana@vm:~$ psql -XAt -p 5434 shop -c "SELECT count(*) FROM orders WHERE customer_id = 31 AND total_cents = 3100"
1
```

`t`, and the order is visible. Two small queries, and the standby is only read when it is known to be
recent enough. This is the same comparison lesson 11 did by eye in `pg_stat_replication`, done by the
application at the moment it matters.
