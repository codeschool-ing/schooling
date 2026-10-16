---
title: Why the planner picks one
version: 1
---

The planner does not have a favourite join. For every pair of inputs it prices all three methods
it can use — and both ways round, since either side can be outer, or hashed — and keeps the
cheapest. The price of each method depends on a few numbers, and the one that moves most is the
**row count it expects from each side**. Change that number and the method changes with it.

## The same join, three sizes

Customers with their orders, for the first 10, 1000 and 20000 customers. Only the range changes:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.731 ms

market=# EXPLAIN SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <= 10;
                                         QUERY PLAN                                         
--------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.93..487.72 rows=100 width=24)
   ->  Index Scan using customers_pkey on customers c  (cost=0.42..8.59 rows=10 width=16)
         Index Cond: (id <= 10)
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.80 rows=11 width=16)
         Recheck Cond: (c.id = customer_id)
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0)
               Index Cond: (customer_id = c.id)
(7 rows)

Time: 3.090 ms

market=# EXPLAIN SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <= 1000;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.85..37897.88 rows=10270 width=24)
   ->  Index Scan using customers_pkey on customers c  (cost=0.42..45.39 rows=1027 width=16)
         Index Cond: (id <= 1000)
   ->  Index Scan using orders_customer_id_idx on orders o  (cost=0.43..36.75 rows=11 width=16)
         Index Cond: (customer_id = c.id)
(5 rows)

Time: 0.820 ms

market=# EXPLAIN SELECT c.name, o.id, o.total_cents FROM customers AS c JOIN orders AS o ON o.customer_id = c.id WHERE c.id <= 20000;
                                             QUERY PLAN                                              
-----------------------------------------------------------------------------------------------------
 Hash Join  (cost=1056.09..42973.20 rows=199890 width=24)
   Hash Cond: (o.customer_id = c.id)
   ->  Seq Scan on orders o  (cost=0.00..36667.00 rows=2000000 width=16)
   ->  Hash  (cost=806.23..806.23 rows=19989 width=16)
         ->  Index Scan using customers_pkey on customers c  (cost=0.42..806.23 rows=19989 width=16)
               Index Cond: (id <= 20000)
(6 rows)

Time: 0.918 ms
```

Ten customers: a nested loop, with the ten customers outside and a bitmap scan of their orders
inside. A thousand: still a nested loop, now with a plain index scan inside. Twenty thousand: a
hash join, with the twenty thousand customers hashed and all two million orders read once past
them.

The arithmetic behind the flip is the arithmetic of lesson 3, and it can be read straight off these
plans:

| outer customers | nested loop ≈ outer rows × one lookup | hash join ≈ one pass over `orders` + the hash |
|---|---|---|
| 10 | 10 × 47.80 ≈ 478 → printed `487.72` | at least `36667` for the scan alone |
| 1000 | 1027 × 36.75 ≈ 37742 → printed `37897.88` | at least `36667` |
| 20000 | 19989 × 36.75 ≈ 734596 | printed `42973.20` |

**A nested loop's cost grows with the outer rows; a hash join's barely does**, because it reads the
big side once whatever happens and only the hash grows. At a thousand customers the loop's 37898 is barely
more than one pass over `orders` alone, and a hash join would add the probing of two million rows to
that pass, so the loop still wins; at twenty thousand the loop would cost
seventeen times the hash join. Somewhere between, the line is crossed, and where depends on the
inputs: the price of a lookup, the size of the table to scan, the memory for the hash.

## Which side goes where

The flip also shows the other choice the planner makes, the **join order**. In both nested loops the
customers are the outer side, because there are fewer of them and the inner side, `orders`, has an
index on `customer_id` to look up. In the hash join the customers are the hashed side, because
20000 rows make a smaller table than two million. In lesson 3's order page the lines were outer and
the products inner, for the same reason the other way round: four lines, and an index on
`products.id`.

With two tables there are only a handful of arrangements to price. With more, the number grows
fast, and the planner searches the orders it can afford to; the rule it follows does not change —
smaller, filtered inputs early and outside, large ones scanned once or looked up through an index.

## The estimate is the input that matters

Every row of that table was computed from an **estimate**: 10, 1027, 19989 customers, 11 orders per
customer. Here the estimates are close to the truth, so the choices are right. Now imagine the
planner expects 10 customers and 200000 arrive. It chooses the nested loop, prices it at a few
hundred, and then runs the inner lookup two hundred thousand times. Nothing about the join was
wrong; it was the right join for a number that was not true.

That is why the first question about a bad join is never "which method should it have used?" but
**"how many rows did it expect on each side, and how many came?"**. Compare `rows` in the estimate
and `rows` in the actual on the children of the join, as lesson 3 taught, and the first big gap you
find from the bottom of the tree is usually the cause of everything above it. Lesson 6 builds that
gap on purpose, with statistics that have gone stale, and follows it up the tree into a join that
picks the wrong method.

And when the estimates are right and the choice is still wrong, as the merge join section found,
the input to question is the price list, not the join.

## The three, side by side

| | nested loop | hash join | merge join |
|---|---|---|---|
| good when | few outer rows, an index on the inner side | two large inputs, one small enough to hash | both inputs already in join order |
| cost grows with | outer rows × lookup | one pass over each side | one pass over each side |
| needs | an index on the inner join column, ideally | memory: `work_mem` × `hash_mem_multiplier` | sorted inputs, or a sort in front |
| the warning sign | `loops` in the thousands where few were expected | `Batches` above 1, the large side hashed | a `Sort` in front of each input |
