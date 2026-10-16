---
title: Naming the standby the primary waits for
version: 1
---

The primary waits only for standbys listed in `synchronous_standby_names`, by the name each one gives
when it connects, its `application_name`. Lesson 11's standby reported `16/standby`, borrowed from the
cluster's name; give it a name of its own when you build it, by passing a connection string to
`pg_basebackup` with `-d` instead of separate options:

```
ana@vm:~$ sudo -u postgres pg_basebackup -d 'host=127.0.0.1 port=5432 user=replicator application_name=standby1' -D /var/lib/postgresql/16/standby -R -C -S standby1 -X stream -c fast
ana@vm:~$ sudo grep -o "application_name=[a-z0-9]*" /var/lib/postgresql/16/standby/postgresql.auto.conf
application_name=standby1
ana@vm:~$ sudo pg_ctlcluster 16 standby start
```

`-R` copied the name into the standby's `primary_conninfo`, so it will introduce itself as
`standby1` every time it connects. (The role, its `.pgpass` and the empty server on port 5434 are made
exactly as in lesson 11.) With a database called `bench` filled by `pgbench -i -s 10`, the benchmark
that comes with PostgreSQL, there is something to measure.

Now make the primary wait for it:

```
shop=# ALTER SYSTEM SET synchronous_standby_names = 'standby1';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

shop=# SELECT application_name, sync_state FROM pg_stat_replication;
 application_name | sync_state 
------------------+------------
 standby1         | sync
(1 row)
```

`sync_state: sync`. From this reload on, every commit on the primary waits until `standby1` has
flushed it, and the next section measures what that costs.
