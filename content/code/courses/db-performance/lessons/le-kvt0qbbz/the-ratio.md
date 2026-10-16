---
title: Two numbers on every node
version: 1
---

Lesson 3 put two brackets on every node of a plan: the planner's guess, `cost=… rows=…`, and what
happened, `actual time=… rows=… loops=…`. This lesson is about the two `rows` side by side. They are
the single most useful pair of numbers in a plan, because **every choice the planner made was made
for the estimate**: the scan, the join, the order of the joins, whether a sort or a hash fits in
memory. When the estimate is right, those choices were made for the data that turned up. When it
is wrong, they were made for some other data.

The belief to drop first is that a slow plan is slow because the planner chose badly. Usually it
chose well, for the numbers it was given. The fix is almost never to overrule the choice; it is to
find the number that was wrong.

One setting for the whole lesson. Parallel plans split every node's rows across processes, as
lesson 3 showed. That makes the comparison harder to read, so turn them off for your session
before each query:

```sql
SET max_parallel_workers_per_gather = 0;
```

## A node that agrees

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.653 ms

market=# EXPLAIN ANALYZE SELECT count(*) FROM orders WHERE seller_id = 42;
                                                                  QUERY PLAN                                                                   
-----------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=38.25..38.26 rows=1 width=8) (actual time=0.332..0.367 rows=1 loops=1)
   ->  Index Only Scan using orders_seller_id_idx on orders  (cost=0.43..34.52 rows=1491 width=0) (actual time=0.099..0.275 rows=1532 loops=1)
         Index Cond: (seller_id = 42)
         Heap Fetches: 0
 Planning Time: 3.227 ms
 Execution Time: 0.597 ms
(6 rows)

Time: 7.175 ms
```

**1491 estimated, 1532 actual.** Divide one by the other and the **ratio** is 1.03: the estimate was
3% low. Lesson 7 works out where 1491 comes from; here it is enough that the two agree. A ratio
between about a half and two is ordinary and changes nothing. Ten is worth reading about. A hundred
is a plan built for a different table.

Two cautions from lesson 3 apply before dividing anything. On a node with `loops` above one, both
numbers are **per loop**, so they compare with each other directly. And a node under a `Limit`
may stop early, so its actual count can be far below its estimate without anything being wrong.

## A node that does not

How many orders did customers in Curitiba place? Join the two tables and count:

```
market=# EXPLAIN ANALYZE SELECT count(*) FROM orders o JOIN customers c ON c.id = o.customer_id WHERE c.city = 'Curitiba' AND c.state = 'PR';
                                                                       QUERY PLAN                                                                       
--------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=9103.19..9103.20 rows=1 width=8) (actual time=69.567..69.569 rows=1 loops=1)
   ->  Nested Loop  (cost=0.43..9079.74 rows=9380 width=0) (actual time=0.033..63.401 rows=135717 loops=1)
         ->  Seq Scan on customers c  (cost=0.00..5283.00 rows=938 width=4) (actual time=0.025..18.451 rows=13578 loops=1)
               Filter: ((city = 'Curitiba'::text) AND (state = 'PR'::text))
               Rows Removed by Filter: 186422
         ->  Index Only Scan using orders_customer_id_idx on orders o  (cost=0.43..3.94 rows=11 width=4) (actual time=0.002..0.002 rows=10 loops=13578)
               Index Cond: (customer_id = c.id)
               Heap Fetches: 0
 Planning Time: 1.989 ms
 Execution Time: 69.694 ms
(10 rows)

Time: 72.886 ms
```

Read it **from the bottom**, the way the rows flow.

1. **`Seq Scan on customers`**: 938 estimated, **13,578** actual. A ratio of 14.5. This is the first
   node, reading upwards, where the two numbers part.
2. **`Index Only Scan on orders`**: 11 estimated, 10 actual, per loop. Fine: each customer has about
   ten orders, as expected. But it ran **13,578 times** instead of 938.
3. **`Nested Loop`**: 9380 estimated, **135,717** actual. Wrong by the same factor of 14.5, and not
   because of anything this node did. It multiplied the rows coming from below by the ten orders
   each, and the rows from below were already wrong.

That is the rule for reading a misestimate: **find the lowest node where estimated and actual
diverge**. Everything above it inherits the error, often multiplied, and looks guilty without being
the cause. A join three levels up showing a ratio of fifty is a symptom; the scan at the bottom
showing fifteen is the disease.

Here the disease is lesson 7's: `city` and `state` say the same thing twice, and the planner
multiplied two fractions that were not independent. The plan survived it, a nested loop over 13,578
customers takes 70 milliseconds, but the same error under a bigger query would choose a nested loop
where a hash join belonged. Lesson 7 shows the fix. This lesson is about the other common cause,
the one with nothing wrong in the design: statistics that describe a table that has since changed.
