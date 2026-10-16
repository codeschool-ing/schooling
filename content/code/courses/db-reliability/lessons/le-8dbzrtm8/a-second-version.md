---
title: A PostgreSQL 17 beside the 16
version: 1
---

Ubuntu 24.04's own packages have PostgreSQL 16 and nothing newer. The simplest way to run 17 on the
same machine, without touching the 16 the rest of the course uses, is **the official image run by
Docker**, which also leaves nothing behind when it is removed. Install Docker from Ubuntu's packages:

```sh
sudo apt install -y docker.io
```

Then start a PostgreSQL 17 container. `--network host` puts it on the machine's own network, so the
two servers reach each other on `127.0.0.1` like every other pair in this course; `-c port=5440`
keeps it off the ports already in use, and the password is for its `postgres` role. The first run
downloads the image, about 170 MB:

```
ana@vm:~$ sudo docker run -d --name pg17 --network host -e POSTGRES_PASSWORD=pg17-pass-1 postgres:17 -c port=5440 > /dev/null
ana@vm:~$ echo '127.0.0.1:5440:*:postgres:pg17-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -XAt -c "SELECT version()"
PostgreSQL 17.11 (Debian 17.11-1.pgdg13+2) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
```

`.pgpass` in your home directory spares you the password from now on; the `chmod` matters, because
`psql` ignores a password file anybody else can read.

## The tables, without the rows

A subscription copies rows into tables that **already exist**; it never creates one. The schema is
copied first, with lesson 2's `pg_dump`, restricted to definitions and stripped of three things
that belong to the publisher: owners and grants naming roles that 17 does not have, and the
publication itself:

```
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -c "CREATE DATABASE shop"
CREATE DATABASE
ana@vm:~$ pg_dump --schema-only --no-owner --no-privileges --no-publications shop | psql -q -o /dev/null -h 127.0.0.1 -p 5440 -U postgres shop
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres shop -c "\dt"
           List of relations
 Schema |   Name    | Type  |  Owner   
--------+-----------+-------+----------
 public | customers | table | postgres
 public | orders    | table | postgres
(2 rows)
```

## Subscribing

The subscription is created on the subscriber, with an ordinary connection string that points at the
publisher:

```
shop=# CREATE SUBSCRIPTION shop_sub CONNECTION 'host=127.0.0.1 port=5432 dbname=shop user=replicator password=replica-pass-1' PUBLICATION shop_pub;
NOTICE:  created replication slot "shop_sub" on publisher
CREATE SUBSCRIPTION
shop=# SELECT count(*) FROM orders;
 count 
-------
 50000
(1 row)

shop=# SELECT subname, received_lsn, latest_end_lsn FROM pg_stat_subscription;
 subname  | received_lsn | latest_end_lsn 
----------+--------------+----------------
 shop_sub | 0/2132E00    | 0/2132E00
(1 row)
```

`created replication slot "shop_sub" on publisher`: a logical subscription holds a slot on the
publisher, like lesson 11's standby, with the same consequence if it stops consuming. The 50,000
orders were copied in the time it took to look, and `pg_stat_subscription` shows the subscriber
following the publisher's log. A new order on the 16:

```
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (41, 4100, now()) RETURNING id;
  id   
-------
 50001
(1 row)

INSERT 0 1

shop=# SELECT slot_name, plugin, slot_type, active FROM pg_replication_slots;
 slot_name |  plugin  | slot_type | active 
-----------+----------+-----------+--------
 shop_sub  | pgoutput | logical   | t
(1 row)
shop=# SELECT id, customer_id, total_cents FROM orders ORDER BY id DESC LIMIT 1;
  id   | customer_id | total_cents 
-------+-------------+-------------
 50001 |          41 |        4100
(1 row)
```

On the 17 a moment later, with the same id. The slot on the 16 is `logical`, and `pgoutput` is the
plugin that turns the log into rows.
