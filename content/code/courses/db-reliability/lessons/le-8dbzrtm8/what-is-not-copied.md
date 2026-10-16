---
title: What the subscriber does not get
version: 1
---

## A column it was never told about

The application gets a new release, and the release adds a column. On the publisher:

```
shop=# ALTER TABLE orders ADD COLUMN note text;
ALTER TABLE

shop=# INSERT INTO orders (customer_id, total_cents, placed_at, note) VALUES (42, 4200, now(), 'gift wrap');
INSERT 0 1
ana@vm:~$ sudo docker logs pg17 2>&1 | grep ERROR | tail -n 2
2026-10-16 03:56:50.736 UTC [71] ERROR:  logical replication target relation "public.orders" is missing replicated column: "note"
2026-10-16 03:56:50.763 UTC [76] ERROR:  logical replication target relation "public.orders" is missing replicated column: "note"
shop=# SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS held FROM pg_replication_slots;
 slot_name | active |   held    
-----------+--------+-----------
 shop_sub  | f      | 336 bytes
(1 row)
```

The insert succeeded on the 16, and the 17 refused to apply it: **the subscriber's table has no column
`note`**, because `ALTER TABLE` is not a row change and logical replication does not carry it. The
subscription's worker stops, retries, and stops again, and while it does, the slot on the publisher is
`active: f` and holds every byte of log from that change on. The 336 bytes are a few seconds' worth on
an idle machine; on a busy one, this is lesson 11's full disk, arriving through a schema change.

The order of operations is therefore fixed: **add a column on the subscriber first**, then on the
publisher. Done the wrong way round, as here, adding it on the subscriber afterwards is enough:

```
shop=# ALTER TABLE orders ADD COLUMN note text;
ALTER TABLE
shop=# SELECT id, total_cents, note FROM orders ORDER BY id DESC LIMIT 2;
  id   | total_cents |   note    
-------+-------------+-----------
 50002 |        4200 | gift wrap
 50001 |        4100 | 
(2 rows)
```

Both rows arrived, `gift wrap` included.

## A sequence that stayed at 1

Order ids come from a sequence, and a sequence's value is not a row:

```
ana@vm:~$ psql -XAt shop -c "SELECT last_value FROM orders_id_seq"
50002
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -XAt shop -c "SELECT last_value FROM orders_id_seq"
1
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (43, 4300, now());
ERROR:  duplicate key value violates unique constraint "orders_pkey"
DETAIL:  Key (id)=(1) already exists.
```

The 16 has handed out ids up to 50002; the 17's sequence has never been used, because every row it
holds arrived with its id already set. **The first insert an application makes on the subscriber
collides** with order 1. On the day the application moves to the 17, that is every insert, until
somebody moves the sequences by hand, and the switch in this lesson's last section does exactly that.
