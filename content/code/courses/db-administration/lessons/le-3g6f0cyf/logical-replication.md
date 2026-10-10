---
title: Logical replication, for the upgrade that cannot stop
version: 1
---

pg_upgrade stops the server for minutes and a dump for hours. When even minutes are too many, the
third way keeps the old server running throughout. **A new server of the new version subscribes to
the old one**: it copies every table once, then receives every change made after that, row by row,
and stays in step for as long as you like. When it has caught up, the switch is a few seconds of
stopped writes while the application's connection moves to the new address.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"A timeline of an upgrade by logical replication. The old 16 server serves the application the whole time until the switch, then is kept for a while and dropped. The new 17 server gets the schema, makes an initial copy of every table, then streams every change as each changed row is sent. At the switch, a few seconds long, writes stop and the application moves to 17, which serves it from then on.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">old, 16</text><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">new, 17</text><rect x=\"120\" y=\"45\" width=\"440\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">serves the application, as always</text><rect x=\"580\" y=\"45\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kept, then dropped</text><rect x=\"120\" y=\"115\" width=\"56\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">schema</text><rect x=\"180\" y=\"115\" width=\"146\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"253.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">initial copy</text><rect x=\"330\" y=\"115\" width=\"226\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"443.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">streams every change</text><rect x=\"580\" y=\"115\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">serves it</text><line x1=\"360\" y1=\"76\" x2=\"360\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"410\" y1=\"76\" x2=\"410\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"460\" y1=\"76\" x2=\"460\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"510\" y1=\"76\" x2=\"510\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"560\" y=\"30\" width=\"20\" height=\"130\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"570\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the switch</text><text x=\"570\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds</text><line x1=\"120\" y1=\"220\" x2=\"700\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"700\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><text x=\"250\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each row changed is sent</text></svg>", "caption": "Logical replication moves the long work out of the downtime: the copy and the catching up happen while the old server keeps serving, and only the switch stops writes."}
```

**This section shows the shape and stops there.** Logical replication is a subject of its own —
monitoring how far behind a subscriber is, what a replication slot costs the publisher, what happens
on a conflict — and db-reliability lesson 14 teaches it. Here it serves one purpose, a major upgrade,
and the session below is the smallest one that shows both the method and the trap in it.

## A publisher

The old server must write enough into its WAL to describe changes row by row, which means
**`wal_level = logical`**, and changing `wal_level` needs a restart. On a real server that restart is
planned weeks ahead, as its own short maintenance window. `main` is not to be restarted in this
lesson, so the publisher here is a third 16 cluster, created with the setting already in place and
filled the same way as the rehearsal:

```
ana@db:~$ sudo pg_createcluster 16 source -o wal_level=logical --start >/dev/null
ana@db:~$ sudo -u postgres pg_dumpall | sudo -u postgres psql -q -p 5436 >/dev/null
ERROR:  role "postgres" already exists
ana@db:~$ psql -p 5436 shop
shop=# SHOW wal_level;
 wal_level 
-----------
 logical
(1 row)

shop=# CREATE PUBLICATION upgrade FOR ALL TABLES;
CREATE PUBLICATION

shop=# \q
```

A **publication** names what is published; `FOR ALL TABLES` is the whole database.

## A subscriber

The new side needs the tables to exist before it can fill them, so it starts from the schema alone.
The restored copy in `17/main` from the previous section is replaced by an empty database, and 17's
`pg_dump` brings the schema over. `--no-publications` leaves out the publication itself, which
would otherwise be copied along with the tables:

```
ana@db:~$ dropdb -p 5434 shop && createdb -p 5434 shop
ana@db:~$ /usr/lib/postgresql/17/bin/pg_dump -p 5436 --schema-only --no-publications shop | psql -q -p 5434 shop >/dev/null
```

```
ana@db:~$ psql -p 5434 shop
shop=# CREATE SUBSCRIPTION upgrade
shop-#     CONNECTION 'host=/var/run/postgresql port=5436 dbname=shop user=postgres'
shop-#     PUBLICATION upgrade;
NOTICE:  created replication slot "upgrade" on publisher
CREATE SUBSCRIPTION

shop=# \q
```

The connection string names `user=postgres` because the process that connects is a background
worker of `17/main`, running as the operating-system user `postgres`, and peer authentication lets
that user in as the role of the same name. The **replication slot** created on the publisher is how
the old server remembers which changes the subscriber still needs. Lesson 7 named the danger: a slot
nobody reads keeps WAL forever.

## Caught up

Each table goes through an initial copy and then reaches state `r`, ready, after which it is
streaming:

```
ana@db:~$ psql -p 5434 shop
shop=# SELECT srrelid::regclass, srsubstate FROM pg_subscription_rel;
  srrelid  | srsubstate 
-----------+------------
 customers | r
 orders    | r
(2 rows)

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)

shop=# \q
```

A new order on the old server:

```
ana@db:~$ psql -p 5436 shop
shop=# INSERT INTO orders (customer_id, status, total_cents, created_at)
shop-# VALUES (42, 'paid', 1999, '2026-10-01 10:00-03') RETURNING id;
   id    
---------
 1000001
(1 row)

INSERT 0 1

shop=# \q
```

reaches the new one within a moment, and so does the trap:

```
ana@db:~$ psql -p 5434 shop
shop=# SELECT id, customer_id, total_cents FROM orders WHERE id > 999999;
   id    | customer_id | total_cents 
---------+-------------+-------------
 1000000 |           1 |         500
 1000001 |          42 |        1999
(2 rows)

shop=# SELECT last_value, is_called FROM orders_id_seq;
 last_value | is_called 
------------+-----------
          1 | f
(1 row)

shop=# \q
```

**The row arrived and the sequence did not.** Logical replication carries rows, and a sequence's
position is not a row of any table: `orders_id_seq` on the subscriber still stands at 1, never used,
while the publisher has handed out 1,000,001 numbers.

## The switch

In a real switch, writes stop on the old server, the subscriber is checked to have every row, and
the application is pointed at the new one. Here the switch is dropping the subscription, which also
removes the slot on the publisher, and then doing what the application would do first: insert a
row.

```
ana@db:~$ psql -p 5434 shop
shop=# DROP SUBSCRIPTION upgrade;
NOTICE:  dropped replication slot "upgrade" on publisher
DROP SUBSCRIPTION

shop=# INSERT INTO orders (customer_id, status, total_cents, created_at)
shop-# VALUES (7, 'paid', 500, '2026-10-02 09:00-03') RETURNING id;
ERROR:  duplicate key value violates unique constraint "orders_pkey"
DETAIL:  Key (id)=(1) already exists.
```

The new server's first order tried to be order number 1. **Every sequence has to be moved past the
largest value in use before the application writes**, and this is the step people forget, because
nothing complains until the first insert:

```
shop=# SELECT setval('orders_id_seq', (SELECT max(id) FROM orders));
 setval  
---------
 1000001
(1 row)

shop=# SELECT setval('customers_id_seq', (SELECT max(id) FROM customers));
 setval 
--------
  50000
(1 row)

shop=# INSERT INTO orders (customer_id, status, total_cents, created_at)
shop-# VALUES (7, 'paid', 500, '2026-10-02 09:00-03') RETURNING id;
   id    
---------
 1000002
(1 row)

INSERT 0 1

shop=# \q
```

The next order is 1,000,002, after the one that came through the subscription. A real cutover runs
the `setval` for every sequence in the database from a query over `pg_sequences`, rather than one by
one from memory.

## What else logical replication does not carry

- **Schema changes.** A `CREATE TABLE` or `ALTER TABLE` on the publisher is not sent. From the
  moment the schema is copied until the switch, nobody changes it.
- **Tables without a primary key**, for `UPDATE` and `DELETE`: the subscriber needs a way to find
  the row, and a publisher refuses those statements on such a table until it has one or a
  `REPLICA IDENTITY` is set.
- **Large objects**, the `lo_` kind, which are not rows of an ordinary table.

That is the price of the near-zero downtime: the most moving parts of the three methods, and a list
of exceptions to check against every database you publish.
