---
title: A standby fed by a standby
version: 1
---

Build a second standby on port 5435 exactly as lesson 11 built the first, with one difference: its
base backup and its connection point at **`standby1` on 5434**, not at the primary. A standby can be
the source of a base backup, and can hold a slot of its own:

```
ana@vm:~$ sudo pg_createcluster 16 standby2 --port 5435 > /dev/null && sudo rm -rf /var/lib/postgresql/16/standby2
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5434 user=replicator application_name=standby2' -D /var/lib/postgresql/16/standby2 -R -C -S standby2 -X stream -c fast
ana@vm:~$ sudo pg_ctlcluster 16 standby2 start
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 standby1         | streaming
(1 row)
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 standby2         | streaming
(1 row)
shop=# SELECT status, sender_port FROM pg_stat_wal_receiver;
  status   | sender_port 
-----------+-------------
 streaming |        5434
(1 row)
```

The primary sees one standby, `standby1`. `standby1` sees one too, `standby2`, streaming from it. And
`standby2`'s receiver reports `sender_port` 5434. The primary sends its log once, whatever happens
downstream; in the picture above, this is the copy that crosses to the other region.

The cost is a chain: `standby2` is behind `standby1` by however far `standby1` is behind, and if
`standby1` stops, `standby2` stops receiving until it is pointed somewhere else, which, after a
promotion, is lesson 15's `primary_conninfo` change again.
