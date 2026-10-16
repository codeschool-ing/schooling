---
title: An upgrade as a switch
version: 1
---

The 17 now holds every order the 16 has, minutes behind at most, and a new order on the 16 reaches
it in seconds. Moving the application from one to the other is the upgrade, and done in this order
it costs the few minutes the application is stopped rather than the hours a dump and restore of a
large database would:

1. **Stop the writes** to the 16: stop the application, or make the 16 refuse them.
2. **Wait until the subscriber has everything**: the slot's position equals the publisher's.
3. **Move every sequence** on the 17 past the highest value used on the 16.
4. **Stop the subscription**, so that nothing written to the 16 by mistake later arrives on the 17.
5. **Point the application at the 17**, and let it write.

Nothing writes to the 16 here, so step 1 holds already. Steps 2 to 4:

```
shop=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind FROM pg_replication_slots WHERE slot_name = 'shop_sub';
 behind  
---------
 0 bytes
(1 row)
ana@vm:~$ max=$(psql -XAt shop -c "SELECT max(id) FROM orders")
ana@vm:~$ echo $max
50002
ana@vm:~$ psql -h 127.0.0.1 -p 5440 -U postgres -XAt shop -c "SELECT setval('orders_id_seq', $max + 1000)"
51002
shop=# ALTER SUBSCRIPTION shop_sub DISABLE;
ALTER SUBSCRIPTION

shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (43, 4300, now()) RETURNING id;
  id   
-------
 51003
(1 row)

INSERT 0 1
```

`0 bytes` behind. The sequence is moved to the highest id **plus a thousand**: a margin is cheap, and
it covers an insert that sneaked in after the maximum was read. With the subscription disabled, the
first order written on the 17 got id 51003 and collided with nothing.

Two things this does not cover, and a real upgrade has a list for each: other objects that are not
rows, such as roles, which `pg_dumpall --roles-only` copies, and the extensions and their versions on
the new server. And the 16 is kept, untouched, until the 17 has run for long enough to trust: it is
the way back.
