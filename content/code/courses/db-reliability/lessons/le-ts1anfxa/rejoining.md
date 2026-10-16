---
title: Bringing the old primary back as a standby
version: 1
---

The 5432 has an order the 5434 will never have, and a log that went its own way after the point the
standby last received. To follow the new primary it has to give that up. **`pg_rewind`** does it by
copying back only the blocks that changed since the two diverged, which is much less than a new base
backup. Stop the old primary and try:

```
ana@vm:~$ sudo pg_ctlcluster 16 main stop
ana@vm:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_rewind --target-pgdata=/var/lib/postgresql/16/main --source-server='port=5434 user=postgres dbname=postgres'
pg_rewind: error: target server needs to use either data checksums or "wal_log_hints = on"
```

It refuses. To find the changed blocks, `pg_rewind` reads the old primary's log, and the log names a
block every time it changes, with one exception: setting the bits PostgreSQL keeps on a row to
remember whether the transaction that wrote it committed, the **hint bits**, writes no log by default. Either `wal_log_hints` or
data checksums makes those changes logged too, and Ubuntu creates clusters with neither. Both have to
be in place **before** the failure, and turning them on needs a restart; neither can help after the
fact.

So this time the old primary is rebuilt from scratch, as a standby of the new one, the way lesson 11
built the first: a base backup with its own name and its own slot on 5434.

```
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/main
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5434 user=replicator application_name=main' -D /var/lib/postgresql/16/main -R -C -S main -X stream -c fast
ana@vm:~$ sudo pg_ctlcluster 16 main start
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

`main` is a standby now, streaming from 5434, and the order of customer 53 is gone with its old data
directory. On a database of terabytes, this is where a failover's hours go.

## Preparing for the next time

Turn `wal_log_hints` on, on **both** servers, since either may be the old primary next time:

```
shop=# ALTER SYSTEM SET wal_log_hints = on;
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 standby restart
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql -XAt shop -c "SHOW wal_log_hints"
off
shop=# ALTER SYSTEM SET wal_log_hints = on;
ALTER SYSTEM
ana@vm:~$ sudo pg_ctlcluster 16 main restart
ana@vm:~$ psql -XAt shop -c "SHOW wal_log_hints"
on
```

The first `SHOW`, on the 5432, still says `off`: `ALTER SYSTEM` was run on the 5434 and wrote the
5434's own `postgresql.auto.conf`, a file that physical replication does not carry. **Every server's
settings are its own**, and a standby built before a change, or a server rebuilt after one, has to be
given it again. Set on the 5432 itself and restarted, it says `on`.
