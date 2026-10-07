---
title: A slot, and what it hands over
version: 1
---

Logical decoding needs the WAL to carry enough to rebuild rows, which is the setting `wal_level`.
The lab set it when it built the database; on a server you do not own, it is the first thing to
ask, because changing it needs a restart:

```
ana@vm:~/etl$ psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)
```

A reader of the stream is represented in the database by a **replication slot**: a named position
in the WAL, plus the plugin that turns WAL into text. The slot remembers how far its reader has
got, and PostgreSQL keeps every byte of WAL the reader has not yet consumed. Ana creates one with
`test_decoding`, the plugin PostgreSQL ships as a demonstration:

```
ana@vm:~/etl$ psql -c "SELECT * FROM pg_create_logical_replication_slot('wh_cdc', 'test_decoding')"
 slot_name |    lsn     
-----------+------------
 wh_cdc    | 0/26E6DF00
(1 row)
```

The number in the `lsn` column is a **log sequence number**: a byte position in the WAL, and on
your machine it will be a different one. From here on, every
change committed to the shop is waiting for the slot's reader. Play a day of trade and look,
without consuming anything, with `peek`:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-01
ana@vm:~/etl$ psql -c "SELECT count(*) FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL)"
 count 
-------
  1088
(1 row)

ana@vm:~/etl$ psql -At -c "SELECT data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) WHERE data LIKE 'table public.customers: UPDATE%' LIMIT 1"
table public.customers: UPDATE: customer_id[integer]:538 name[text]:'Pedro Machado' email[text]:'pedro.machado538@example.net' city[text]:'Campinas' state[text]:'SP' created_at[timestamp with time zone]:'2025-05-10 12:00:00-03' updated_at[timestamp with time zone]:'2026-03-01 08:07:37-03'
ana@vm:~/etl$ psql -c "SELECT lsn, xid, left(data, 60) AS data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) LIMIT 7"
    lsn     |  xid  |                             data                             
------------+-------+--------------------------------------------------------------
 0/26F63478 | 51696 | BEGIN 51696
 0/26F63478 | 51696 | table public.orders: INSERT: order_id[integer]:117013 shop_i
 0/26F6A170 | 51696 | table public.order_lines: INSERT: order_id[integer]:117013 l
 0/26F6EAF8 | 51696 | table public.payments: INSERT: payment_id[integer]:517013 or
 0/26F70F68 | 51696 | COMMIT 51696
 0/26F70F68 | 51697 | BEGIN 51697
 0/26F70F68 | 51697 | table public.orders: INSERT: order_id[integer]:117014 shop_i
(7 rows)
```

1,088 lines for one day: a `BEGIN` and a `COMMIT` around each of the 211 transactions, and 666
changed rows between them. **Each transaction arrives whole, and only once it has committed**: a
transaction that rolled back never appears, and one that took twenty minutes appears at its commit,
not at its start. That is the slow till's problem from lesson 4, gone — the order of the stream is
the order things became true.

The `UPDATE` line shows the whole new row, every column with its type. What it does not show is
the row before the update; the section after next is about that.
