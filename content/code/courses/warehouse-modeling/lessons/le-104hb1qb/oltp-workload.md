---
title: What the till needs
version: 1
---

The name for the till's side is **OLTP**, online transaction processing. The word that matters is
*transaction*: a small unit of work that either happens completely or not at all, many of them a
second, each from a different person.

Ask PostgreSQL to fetch the order the till just wrote, and to say how it did it:

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT o.ordered_at, o.status, l.line_no, l.book_id, l.quantity, l.unit_price_cents
FROM orders o JOIN order_lines l USING (order_id)
WHERE o.order_id = 900001;
```

```
ana@lab:~/wh$ psql -f one-order.sql
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Nested Loop (actual time=0.126..0.128 rows=2 loops=1)
   Buffers: shared hit=11
   ->  Index Scan using orders_pkey on orders o (actual time=0.087..0.087 rows=1 loops=1)
         Index Cond: (order_id = 900001)
         Buffers: shared hit=7
   ->  Index Scan using order_lines_pkey on order_lines l (actual time=0.036..0.036 rows=2 loops=1)
         Index Cond: (order_id = 900001)
         Buffers: shared hit=4
 Planning:
   Buffers: shared hit=188
 Planning Time: 0.596 ms
 Execution Time: 0.192 ms
(12 rows)
```

Read the plan from the inside out. An **index scan** on `orders_pkey` walked the primary key's
B-tree to order 900001 and read 7 pages. A second index scan on `order_lines_pkey` found its two
lines in 4 more. **Eleven pages of 8 kB, in 0.192 milliseconds**, out of a table of nearly nine
hundred thousand lines. The size of the table barely enters into it: a B-tree over a million keys
is three or four levels deep, so a table ten times larger costs a lookup about one page more.

Everything about the operational schema serves that shape of work:

- **Normalised tables.** A customer's city is stored once, in `customers`. Changing it is one
  `UPDATE` of one row, and no order needs touching. That is what third normal form buys, and
  `sql-databases` lesson 2 spent a whole lesson earning it.
- **An index for every way a row is looked up.** By order number, by customer, by date. Each one
  makes a lookup cheap and every insert a little dearer, a trade that pays when lookups are by key.
- **Constraints that refuse bad data at the door.** A line naming a book that does not exist is
  refused by the foreign key, at the moment it is written, while the person who typed it is still
  there to fix it.
- **The current state, and only the current state.** The row in `customers` says where the customer
  lives *now*. When it changes, the old value is gone from that row.

**That last one is a design decision, not a flaw.** A till does not need to know where a customer
lived last year. Section 08 shows what it costs somebody who does.
