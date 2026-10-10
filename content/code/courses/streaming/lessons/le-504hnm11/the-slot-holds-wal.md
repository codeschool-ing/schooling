---
title: The slot that holds the WAL
version: 1
---

**A stopped connector does not lose data; it makes the database keep it.** That is the promise of a
replication slot, and it is also the most common way CDC takes a production database down. The
connector stops — a failed deploy, a broker outage, credentials that expired over a weekend — and
nobody notices, because nothing is failing: the website works, the table is fine, and the topic
simply receives nothing. Meanwhile PostgreSQL keeps every WAL file written since the slot's last
confirmed position, and the disk under the database fills.

Make it happen. In the second shell, stop Connect with Ctrl+C. Back in the first, this query shows
each slot, whether anybody is reading it, and two distances measured in bytes of WAL: how far the
reader is behind the server now, and how much WAL the server is keeping because of it:

```
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
```

`active` is `f`: nobody is connected. Now the shop goes on working. Somebody builds a table of
notes that has nothing to do with CDC and is not in the publication, and then a delivery tops up
every shop's stock by one copy of everything:

```
ubuntu@stream:~/work$ psql pontofinal -c "CREATE TABLE notes AS SELECT g AS id, md5(g::text) AS body FROM generate_series(1, 200000) g"
```

**The notes table is not published, and its WAL is kept all the same.** The WAL is one stream for the
whole server; a slot holds back all of it from its position onwards, whatever tables the bytes
belong to. A slot reading two small tables in a database where something else writes gigabytes an
hour holds those gigabytes.

## Catching up

Start Connect again in the second shell, with the same command as before. It finds its position in
`connect.offsets`, asks the slot for everything after it, and does not take a second snapshot.
Then, in the first shell:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic pf.public.stock
```

The forty updates made while it was stopped are on the topic, after the 44 messages that were there
before. Nothing was lost, which is the slot doing its job. And on the database's side, the reader is
back:

```
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
```

## What to watch, and the limit to set

**The retained size of every slot is the number to alert on**, with the query above or its
equivalent in whatever monitors the database, and `active = f` for longer than a deploy takes is the
second. A slot with no reader is either an outage to fix or a leftover to drop with
`pg_drop_replication_slot` — and a connector that is being retired for good should have its slot
dropped the same day, because nothing else ever will.

PostgreSQL also has a fuse, off by default:

```
ubuntu@stream:~/work$ psql pontofinal -c "SHOW max_slot_wal_keep_size"
```

`-1` means no limit. Set to, say, `50GB`, PostgreSQL stops keeping WAL for a slot past that size and
marks the slot as lost. **That trades the database's disk for the connector's completeness**: the
database survives, and the connector has to take a new snapshot, because the changes it missed are
gone. Most teams choose that trade, deliberately, with the limit sized to the outage they can
recover from.

One more setting closes a quieter version of the same problem. A slot's position only moves when
the connector confirms a change it read, so if the published tables are quiet while others are busy
— `stock` changing once a day in a database that writes all night — the slot sits still and the WAL
grows even with Connect running. Debezium's `heartbeat.interval.ms` makes the connector confirm its
position on a timer whether or not its tables changed. It is not set in this lab.

Before leaving this lesson, stop Connect with Ctrl+C in the second shell. PostgreSQL can keep
running; it does nothing until something writes to it.
