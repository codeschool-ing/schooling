---
title: A switchover, which loses nothing
version: 1
---

Now the planned direction, from 5434 back to 5432. A clean shutdown of a primary does something a
crash does not: before it stops, it writes a final **shutdown checkpoint** and waits until its
connected standbys have received the log up to it. So stop the primary cleanly, and compare where it
stopped with what the standby replayed:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ sudo /usr/lib/postgresql/16/bin/pg_controldata /var/lib/postgresql/16/standby | grep -E 'cluster state|Latest checkpoint location'
Database cluster state:               shut down
Latest checkpoint location:           0/6000110
shop=# SELECT pg_last_wal_replay_lsn();
 pg_last_wal_replay_lsn 
------------------------
 0/6000188
(1 row)
ana@vm:~$ sudo pg_ctlcluster 16 main promote
shop=# SELECT pg_create_physical_replication_slot('standby1');
 pg_create_physical_replication_slot 
-------------------------------------
 (standby1,)
(1 row)
ana@vm:~$ sudo -u postgres touch /var/lib/postgresql/16/standby/standby.signal
ana@vm:~$ sudo grep -E "primary_conninfo|primary_slot_name" /var/lib/postgresql/16/standby/postgresql.auto.conf
primary_conninfo = 'user=replicator passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer host=127.0.0.1 port=5432 application_name=standby1 sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
primary_slot_name = 'standby1'
ana@vm:~$ sudo pg_ctlcluster 16 standby start
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 standby1         | streaming
(1 row)
```

The stopped primary's last checkpoint record starts at `0/6000110`; the standby has replayed to
`0/6000188`, through the end of that record. **The standby has every byte the primary wrote**, which
is what makes this a switchover rather than a failover: nothing is lost, and nothing has to be
rewound.

The old primary needs only what every standby in this course has had: an empty `standby.signal`, and
a `primary_conninfo` with a slot. It still has those two settings in its `postgresql.auto.conf`,
written there by `pg_basebackup -R` in the first place and left alone when it was promoted, pointing
at port 5432 with the name `standby1`. A promoted server ignores them, so they were waiting. All it
lacked was the slot on the new primary, created first, and the signal file. It started, and streamed.

The order of a switchover, then, which lesson 23 turns into a rehearsal:

1. Stop the writes, or accept that the few in flight will fail and be retried.
2. Stop the primary **cleanly**.
3. Confirm the standby replayed past the primary's last checkpoint.
4. Promote the standby.
5. Make the old primary a standby of the new one, and start it.
6. Point the application at the new primary.
