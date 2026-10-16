---
title: A failover by hand
version: 1
---

Place an order, then kill the primary as a crash would, with `kill -9` of its main process: no
shutdown, no checkpoint, nothing said to the standby. The process ID is the first line of
`postmaster.pid` in the data directory.

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (51, 5100, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1
ana@vm:~$ sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  standby 5434 online postgres /var/lib/postgresql/16/standby /var/log/postgresql/postgresql-16-standby.log
```

`down`. Before promoting, ask the standby the second question:

```
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)

shop=# SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();
 pg_last_wal_receive_lsn | pg_last_wal_replay_lsn 
-------------------------+------------------------
 0/4006608               | 0/4006608
(1 row)

shop=# SELECT max(id) FROM orders;
  max  
-------
 50001
(1 row)

shop=# SELECT status FROM pg_stat_wal_receiver;
 status 
--------
(0 rows)
```

Still in recovery, and its received and replayed positions are equal, so nothing it has is waiting to
be applied. Order `50001` is there. Whether the primary wrote anything after the last byte the standby
received cannot be known from here, and that is the honest limit of an asynchronous failover: the
standby knows what it has, never what it missed. `pg_stat_wal_receiver` is empty, because the
receiver has nobody to receive from.

Promote it:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby promote
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 f
(1 row)

shop=# SELECT timeline_id FROM pg_control_checkpoint();
 timeline_id 
-------------
           2
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (52, 5200, now()) RETURNING id;
  id   
-------
 50034
(1 row)

INSERT 0 1
```

Out of recovery, accepting writes, on **timeline 2**. A promotion starts a new timeline, as lesson
6's recovery did, so that the log written from now on can never be confused with the old primary's.
The new order's id is `50034`, not `50002`: a sequence logs its values ahead in batches of 32, and the
standby replayed the batch, not the last value handed out. Ids skip after every promotion, and nothing
should depend on them being consecutive.

The application still points at port 5432, where there is nothing. Moving it is lesson 19's subject;
here, the new primary is on 5434.
