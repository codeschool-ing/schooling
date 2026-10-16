---
title: The next crash, rewound
version: 1
---

With `wal_log_hints` on both servers, crash the primary on 5432 again and fail over to 5434, without
waiting for anything:

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (54, 5400, now()) RETURNING id;
  id   
-------
 50035
(1 row)

INSERT 0 1
ana@vm:~$ sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)
ana@vm:~$ sudo pg_ctlcluster 16 standby promote
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (55, 5500, now()) RETURNING id;
  id   
-------
 50068
(1 row)

INSERT 0 1
```

Order `50035` on the old primary, then the crash, then order `50068` on the new one: the same
divergence as before, the same skip of 32 in the ids. This time `pg_rewind` can do its job. Two
options matter on Ubuntu: `--config-file`, because Ubuntu keeps `postgresql.conf` in
`/etc/postgresql`, not in the data directory where `pg_rewind` would look for it, and without it the
command fails at its first step; and `--write-recovery-conf`, which makes the result a standby of the
source server.

```
ana@vm:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_rewind --target-pgdata=/var/lib/postgresql/16/main --source-server='port=5434 user=postgres dbname=postgres application_name=main' --config-file=/etc/postgresql/16/main/postgresql.conf --write-recovery-conf
pg_rewind: executing "/usr/lib/postgresql/16/bin/postgres" for target server to complete crash recovery
2026-10-16 01:10:29.950 -03 [10480] LOG:  database system was interrupted; last known up at 2026-10-16 01:10:15 -03
2026-10-16 01:10:29.950 -03 [10480] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-16 01:10:29.951 -03 [10480] LOG:  redo starts at 0/60001B8
2026-10-16 01:10:29.951 -03 [10480] LOG:  invalid record length at 0/6006978: expected at least 24, got 0
2026-10-16 01:10:29.951 -03 [10480] LOG:  redo done at 0/6006950 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
2026-10-16 01:10:29.952 -03 [10480] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-16 01:10:29.953 -03 [10480] LOG:  checkpoint complete: wrote 8 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.000 s, total=0.001 s; sync files=0, longest=0.000 s, average=0.000 s; distance=25 kB, estimate=25 kB; lsn=0/6006978, redo lsn=0/6006978

PostgreSQL stand-alone backend 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
backend> 2026-10-16 01:10:29.956 -03 [10480] LOG:  checkpoint starting: shutdown immediate
2026-10-16 01:10:29.956 -03 [10480] LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.001 s, total=0.001 s; sync files=0, longest=0.000 s, average=0.000 s; distance=0 kB, estimate=23 kB; lsn=0/60069F0, redo lsn=0/60069F0
pg_rewind: servers diverged at WAL location 0/6006978 on timeline 3
pg_rewind: rewinding from last common checkpoint at 0/60001F0 on timeline 3
pg_rewind: Done!
ana@vm:~$ sudo grep -E "primary_conninfo|primary_slot_name" /var/lib/postgresql/16/main/postgresql.auto.conf
primary_conninfo = 'user=replicator passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer host=127.0.0.1 port=5432 application_name=standby1 sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
primary_slot_name = 'standby1'
primary_conninfo = 'user=postgres passfile=''/var/lib/postgresql/.pgpass'' channel_binding=prefer port=5434 application_name=main sslmode=prefer sslcompression=0 sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable'
ana@vm:~$ sudo pg_ctlcluster 16 main start
ana@vm:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-16 01:10:36.209 -03 [10517] FATAL:  could not start WAL streaming: ERROR:  replication slot "standby1" does not exist
2026-10-16 01:10:36.209 -03 [10501] LOG:  waiting for WAL to become available at 0/6002000
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name | state 
------------------+-------
(0 rows)

shop=# SELECT slot_name, active FROM pg_replication_slots;
 slot_name | active 
-----------+--------
 main      | f
(1 row)
ana@vm:~$ psql -XAt shop -c "SELECT pg_is_in_recovery()"
t
```

The first lines are a crash recovery: the old primary had been killed, and `pg_rewind` first brings it
to a consistent, cleanly stopped state, in single-user mode. Then it finds where the two histories
**diverged**, `0/6006978` on timeline 3, and copies back from the new primary whatever changed after
the last checkpoint they shared. `Done!`: it copied what changed since the divergence, not the whole directory, which on a large
database is the difference between minutes and hours, and the reason to have turned `wal_log_hints`
on.

And then it does not stream. The `grep` shows why: `pg_rewind` copies the source's configuration
files too, so the old primary received the 5434's `postgresql.auto.conf`, with the 5434's old
`primary_slot_name = 'standby1'`, and its own new `primary_conninfo` appended below it. There is no slot
`standby1` on the 5434. The slot that is there, `main`, is the one the rebuild in this lesson made, and
it is inactive. Point the standby at it:

```
ana@vm:~$ sudo -u postgres psql -c "ALTER SYSTEM SET primary_slot_name = 'main'"
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main reload
shop=# SELECT application_name, state FROM pg_stat_replication;
 application_name |   state   
------------------+-----------
 main             | streaming
(1 row)

shop=# SELECT slot_name, active FROM pg_replication_slots;
 slot_name | active 
-----------+--------
 main      | t
(1 row)
```

Streaming. Two lessons in that last step. **Every tool that copies a data directory copies its
configuration**, and the settings that name a server's role and its partner are the ones that end up
wrong. And a failover is not finished when the new primary takes writes; it is finished when the old
one is a standby again, streaming, which is the check to end every failover on.
