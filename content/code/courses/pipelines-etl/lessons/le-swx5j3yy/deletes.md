---
title: The change an incremental load cannot see
version: 1
---

On 14 March a customer asks Ponto Final to forget them, and the back office does what the law
requires — it detaches their orders and deletes their row:

```
ana@vm:~/etl$ sudo shop until 2026-03-14
ana@vm:~/etl$ grep -A2 "SET customer_id = NULL" /var/lib/etl-data/days/2026-03-14.sql
UPDATE orders SET customer_id = NULL, updated_at = '2026-03-14 10:14:53-03:00' WHERE customer_id = 1880;
DELETE FROM customers WHERE customer_id = 1880;
COMMIT;
ana@vm:~/etl$ python incremental.py customers
shop.customers: 294 rows since 03-01 22:21:41, watermark now 03-14 22:46:33
ana@vm:~/etl$ python full_customers.py
raw.customers: 5345 rows, all of them
ana@vm:~/etl$ psql -c "SELECT count(*) AS in_the_shop FROM customers WHERE customer_id = 1880"
 in_the_shop 
-------------
           0
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT (SELECT count(*) FROM raw.customers_changes WHERE customer_id = 1880) AS incremental, (SELECT count(*) FROM raw.customers WHERE customer_id = 1880) AS full_copy"
 incremental | full_copy 
-------------+-----------
           1 |         0
(1 row)
```

The incremental extraction ran that night and read 294 changed customers. The deleted one was not
among them, and could not have been: **a deleted row has no `updated_at`, because it has no row.**
The incremental copy in the warehouse still holds customer 1880, name, e-mail and city, and will
until somebody notices. The full copy, rebuilt from scratch the same night, simply does not have
them.

A warehouse that keeps an erased customer's e-mail after the shop deleted it is keeping personal
data nobody may keep any more, and the pipeline is how it got there.

## Four ways to see a delete

- **A full load of the table**, for tables small enough to afford it. `customers` is five thousand
  rows; reloading it nightly costs nothing and makes deletes impossible to miss.
- **Compare the keys.** Extract only the ids from the source, every night, and delete from the
  warehouse whatever is no longer there. Cheaper than a full load, because ids are small, and it
  still reads every row's key.
- **Soft deletes in the source.** The source never deletes; it sets `deleted_at` and leaves the
  row. Now a delete is an update, `updated_at` moves, and an incremental extraction sees it. This
  needs the source's owners to agree, and it is wrong for an erasure, where the row has to go.
- **Read the database's log.** Every delete is written there, in commit order, and lesson 5 reads
  it.

The orders the erased customer placed are a separate matter, and the back office handled it: their
`customer_id` was set to `NULL` and `updated_at` moved, so the incremental extraction of orders
*did* see that change. **An update to a row is visible to a watermark; the disappearance of a row
is not.**
