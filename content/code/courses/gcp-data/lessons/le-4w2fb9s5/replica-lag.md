---
title: A replica on the laptop, and the lag you can watch
version: 1
---

**This section is PostgreSQL, not Cloud SQL.** Cloud SQL builds a PostgreSQL replica with the
engine's own streaming replication, and the engine is on your laptop since lesson 6, so the mechanism
can be run, stopped and measured here. What Cloud SQL adds around it, the copy it takes for you, the
instance it creates, the address it gives the replica, is the previous section and is not here.

Every command below runs in a terminal with lesson 6's variables exported:

```sh
export PATH=/usr/lib/postgresql/16/bin:$PATH PGHOST=localhost PGPORT=5433 PGUSER=postgres
```

If `~/gcp/pg/orders` does not exist because lesson 6 was read rather than practised, its `initdb`
line in "Database flags, practised on the engine itself" makes it.

## The primary, with something to replicate

Start lesson 6's cluster on 5433 and give it a table of a thousand orders:

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -c 'CREATE TABLE orders (id bigint PRIMARY KEY, customer text NOT NULL, total_cents integer NOT NULL, created timestamptz NOT NULL DEFAULT now())' -c "INSERT INTO orders (id, customer, total_cents) SELECT g, 'c-' || g % 50, 1000 + g FROM generate_series(1, 1000) g"
CREATE TABLE
INSERT 0 1000
```

## A replica in three commands

**`pg_basebackup` copies a running server's data directory over a replication connection**, which
is what Cloud SQL does for you when a replica is created. `-R` writes the settings that make the copy
a replica, `-X stream` brings the log written during the copy along with it, and `-c fast` asks the
primary for a checkpoint now rather than at its next scheduled one:

```
ana@laptop:~/gcp$ pg_basebackup -D ~/gcp/pg/reports -R -X stream -c fast
ana@laptop:~/gcp$ ls ~/gcp/pg/reports | head -4 && ls ~/gcp/pg/reports/standby.signal && grep primary_conninfo ~/gcp/pg/reports/postgresql.auto.conf | cut -c1-80
PG_VERSION
backup_label
backup_manifest
base
/home/ana/gcp/pg/reports/standby.signal
primary_conninfo = 'user=postgres passfile=''/home/ana/.pgpass'' channel_binding
```

**The copy is a whole data directory**, and two things in it make it a replica: a file called
`standby.signal`, whose presence tells the server to start in recovery and stay there, and a
`primary_conninfo` line, which tells it where to stream from. The defaults of PostgreSQL 16 are
enough on the primary's side: `initdb` set `wal_level` to `replica` and allowed ten replication
connections, and `--auth=trust` let the local one in.

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/reports -o "-p 5434 -k $HOME/gcp/pg" -l ~/gcp/pg/reports.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -p 5434 -Atc 'SELECT pg_is_in_recovery(), count(*) FROM orders'
t|1000
ana@laptop:~/gcp$ psql -c 'SELECT application_name, state, sync_state FROM pg_stat_replication'
 application_name |   state   | sync_state 
------------------+-----------+------------
 walreceiver      | streaming | async
(1 row)
```

**`t` from `pg_is_in_recovery()`, and the thousand orders**, on port 5434. On the primary,
`pg_stat_replication` has a line per replica connected to it, and `sync_state` says `async`: the
primary does not wait for this one, which is the asynchronous half of the figure in the previous
section.

## A replica refuses writes

```
ana@laptop:~/gcp$ psql -p 5434 -c "INSERT INTO orders (id, customer, total_cents) VALUES (5001, 'c-7', 4590)"
ERROR:  cannot execute INSERT in a read-only transaction
```

**The engine itself refuses**, not a setting somebody remembered to make: a server in recovery runs
every transaction read-only. A Cloud SQL read replica refuses the same way, because it is the same
engine in the same state. An application that sends its writes to the replica's address finds out on
its first `INSERT`.

## The lag, made visible

On a laptop the lag is a few milliseconds, too short to see. So stop the replica from applying what
it receives, write on the primary, and look at both:

```
ana@laptop:~/gcp$ psql -p 5434 -c 'SELECT pg_wal_replay_pause()'
 pg_wal_replay_pause 
---------------------
 
(1 row)

ana@laptop:~/gcp$ psql -c "INSERT INTO orders (id, customer, total_cents) SELECT g, 'c-' || g % 50, 1000 + g FROM generate_series(1001, 1100) g"
INSERT 0 100
ana@laptop:~/gcp$ psql -Atc 'SELECT count(*) FROM orders' && psql -p 5434 -Atc 'SELECT count(*) FROM orders'
1100
1000
ana@laptop:~/gcp$ psql -c 'SELECT pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind, replay_lag FROM pg_stat_replication'
 bytes_behind |   replay_lag    
--------------+-----------------
        21952 | 00:00:00.042561
(1 row)

ana@laptop:~/gcp$ psql -p 5434 -c 'SELECT pg_wal_replay_resume()' && sleep 1 && psql -p 5434 -Atc 'SELECT count(*) FROM orders'
 pg_wal_replay_resume 
----------------------
 
(1 row)

1100
ana@laptop:~/gcp$ psql -c 'SELECT pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication'
 bytes_behind 
--------------
            0
(1 row)
```

**The primary has 1,100 orders and the replica 1,000.** The replica received the hundred, and
`bytes_behind` is how much log it holds and has not applied, 21,952 bytes; `replay_lag` is the time
the primary measured between sending and the replica's last report of having applied, which is about
the replica's state before the pause. Resuming takes the count to 1,100 and the gap to 0.

**That is what lag looks like on a real replica**, without the pause: a report run in the gap reads a
thousand orders while the primary has eleven hundred. What makes it large on a real instance is
anything that slows the replay: a replica on a smaller machine than its primary, a long query on the
replica that the replay has to wait for, or a bulk load on the primary that writes log faster than the
replica applies it. Cloud SQL publishes the lag as a metric of the replica in Cloud Monitoring, and an
alert on it is how a team finds out before the report is wrong.

The two servers stay up for the next section, which makes a mistake on the primary and watches the
replica copy it.
