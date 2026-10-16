---
title: Watching it stream
version: 1
---

Start the standby, and the machine has two servers running, one following the other:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby start
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  standby 5434 online postgres /var/lib/postgresql/16/standby /var/log/postgresql/postgresql-16-standby.log
```

The primary sees the standby as a connection, in `pg_stat_replication`. `\x` asks `psql` for one
column per line, which suits a view this wide:

```
shop=# \x
Expanded display is on.

shop=# SELECT application_name, client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, sync_state FROM pg_stat_replication;
-[ RECORD 1 ]----+-----------
application_name | 16/standby
client_addr      | 127.0.0.1
state            | streaming
sent_lsn         | 0/4000000
write_lsn        | 0/4000000
flush_lsn        | 0/4000000
replay_lsn       | 0/4000000
sync_state       | async
```

**`state: streaming`**, and four positions in the log that say how far each step of the last section
has got: sent by the primary, written, flushed and replayed by the standby. Here they are all the same,
`0/4000000`, because nothing has been written since the standby connected. When they differ, the
differences are replication lag, and lesson 13 measures them. `sync_state: async` says the primary
does not wait for this standby before confirming a commit; lesson 12 changes that.

The standby has its own view of the same connection:

```
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)

shop=# SELECT status, sender_host, sender_port, slot_name FROM pg_stat_wal_receiver;
  status   | sender_host | sender_port | slot_name 
-----------+-------------+-------------+-----------
 streaming | 127.0.0.1   |        5432 | standby1
(1 row)
```

`pg_is_in_recovery()` is true, because a standby is a server permanently in recovery, and its WAL
receiver is streaming from 127.0.0.1:5432 through the slot `standby1`.

## Reads, and the write it refuses

Insert an order on the primary, and read it on the standby a second later:

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (11, 4200, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1
shop=# SELECT id, total_cents FROM orders ORDER BY id DESC LIMIT 1;
  id   | total_cents 
-------+-------------
 50001 |        4200
(1 row)

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (12, 100, now());
ERROR:  cannot execute INSERT in a read-only transaction
```

The order was there, with its id and total, on a server nobody wrote to. And the same insert sent to
the standby was refused: **`cannot execute INSERT in a read-only transaction`**. An application that
sends reads to a standby has to send every write to the primary, and lesson 19 is about how it finds
out which server that is.
