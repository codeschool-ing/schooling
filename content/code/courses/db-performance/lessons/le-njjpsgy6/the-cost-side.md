---
title: What the change costs, measured on its own
version: 1
---

The workload could not see the cost of the new index in the write latency: the noise was bigger.
That does not make the cost zero. It means it has to be measured in a unit the workload's noise does
not drown, and an index has three such units.

## Space

```
market=# SELECT pg_size_pretty(pg_relation_size('orders_customer_placed_idx')) AS new_index, pg_size_pretty(pg_relation_size('orders_customer_id_idx')) AS old_index;
 new_index | old_index 
-----------+-----------
 60 MB     | 18 MB
(1 row)
```

**60 MB** for the new index, against **18 MB** for the one on `customer_id` alone that it would
replace or sit beside. The new one is more than three times larger although it adds one column of
eight bytes, and the reason is worth knowing: PostgreSQL's B-tree stores a value that repeats only
once, with a list of the rows that carry it. Each customer has about ten orders, so the old index
holds two hundred thousand `customer_id` values and a list for each. In the new one, every key is a
customer **and a moment**, unique, and nothing can be shared.

Those 60 MB are paid three times: on the disk, in the backups, and in memory, where the index competes
with the tables for the 128 MB of `shared_buffers` and for the operating system's cache. A database
that fitted in memory before can stop fitting after enough changes like this one, and nothing about
any one of them will look like the cause.

## Writes

Every row inserted into `orders` now writes one more index entry, and every update that changes
`customer_id` or `placed_at` does too. Lesson 11 measured that tax directly, with many indexes and
few, and showed that it is real per index. Here it hides inside eight milliseconds of a transaction
that also inserts an order line and updates a total, which is why the workload cannot show it — and
on an application that writes far more than this one, the same index would be a visible cost.

## People

The third cost is not in any table. Every index is something the next person has to understand
before they can change `orders`: why is it there, which query needs it, is it safe to drop? An index
with no record of why it was built is one nobody dares remove, and lesson 11 found what that looks
like after three years: duplicates, overlaps and indexes nobody reads, each of them reasonable on the
day it was made.

## The cost a benchmark cannot see

All three costs are paid **continuously**, and the benefit only when the query runs. That asymmetry
is what the arithmetic in the next section is for: a change pays for itself only when the time it
saves, added up over every run, is larger than what it costs every day whether or not anyone asks.
