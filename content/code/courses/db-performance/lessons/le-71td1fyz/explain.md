---
title: What EXPLAIN prints, and what it does not do
version: 1
---

`sql-databases` lesson 10 introduced `EXPLAIN`: put it in front of a query and PostgreSQL **plans
the query without running it** and prints the plan, a tree of steps called nodes, each with the
planner's prediction beside it. This section recaps that in a page, on the query lesson 2's
workload sends most often, and then adds the part that lesson left alone: why every cost is two
numbers, and what the first one is for.

The belief to drop first is that `EXPLAIN` tells you how long a query takes. It tells you what the
planner **expects**, in units of its own, and nothing has run when it answers.

## One customer's last ten orders

Half of lesson 2's traffic was this query, the "my orders" screen. Open `psql market` and ask for
its plan, for customer 4242:

```
market=# EXPLAIN SELECT id, placed_at, status, total_cents FROM orders WHERE customer_id = 4242 ORDER BY placed_at DESC LIMIT 10;
                                            QUERY PLAN                                            
--------------------------------------------------------------------------------------------------
 Limit  (cost=47.99..48.02 rows=10 width=29)
   ->  Sort  (cost=47.99..48.02 rows=11 width=29)
         Sort Key: placed_at DESC
         ->  Bitmap Heap Scan on orders  (cost=4.51..47.80 rows=11 width=29)
               Recheck Cond: (customer_id = 4242)
               ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0)
                     Index Cond: (customer_id = 4242)
(7 rows)

Time: 2.787 ms
```

Seven lines, four nodes. A node is the line with a name at the start — `Limit`, `Sort`,
`Bitmap Heap Scan`, `Bitmap Index Scan` — and each `->` hangs a node under the one above it. The
indented lines with no arrow are details of the node just above them: the key it sorts by, the
condition it applies. How to read the order of the four is the next section; here, read one line
across.

```
Bitmap Heap Scan on orders  (cost=4.51..47.80 rows=11 width=29)
```

**`rows=11` is how many rows the node expects to pass up** to the node above it, not how many it
reads. The planner thinks customer 4242 has about eleven orders, from statistics it keeps about
the column; lessons 6 and 7 are about where that number comes from and what happens when it is
wrong.

**`width=29` is the average size of one of those rows, in bytes.** Four columns were asked for,
so 29. The `Bitmap Index Scan` below it says `width=0`, because it passes no rows at all: it hands
its parent a list of pages to visit, and lesson 4 takes that apart. Width matters wherever rows
have to be held in memory, by a sort or a hash, and it is why `SELECT *` costs more than the four
columns a screen shows.

**`cost=4.51..47.80` is two numbers, and neither is a time.** They are in the planner's own unit,
which the last section of this lesson works out by hand. The planner prices every plan it can
think of and keeps the cheapest, so the cost is the reason the plan you are reading was chosen.

## `EXPLAIN` on its own runs nothing

That includes statements that change data. Ask for the plan of a delete and then count what it
would have deleted:

```
market=# EXPLAIN DELETE FROM order_lines WHERE order_id = 7;
                                        QUERY PLAN                                         
-------------------------------------------------------------------------------------------
 Delete on order_lines  (cost=0.43..11.98 rows=0 width=0)
   ->  Index Scan using order_lines_pkey on order_lines  (cost=0.43..11.98 rows=3 width=6)
         Index Cond: (order_id = 7)
(3 rows)

Time: 1.841 ms

market=# SELECT count(*) FROM order_lines WHERE order_id = 7;
 count 
-------
     4
(1 row)

Time: 0.878 ms
```

A plan for deleting order 7's lines, and the four lines are still there. That is what makes plain
`EXPLAIN` safe to type at a production server, and it is exactly the property the word `ANALYZE`
takes away, two sections on.

## Startup cost and total cost

**The first number is what the node costs before it can hand up its first row; the second is
what it costs to hand up all of them.** For most nodes the two are far apart, and the gap is the
whole point. Two queries that want the ten earliest orders and the ten cheapest show it. The first
line below switches off parallel plans for this `psql` session, so that each plan is one plain
tree; lesson 4 explains the parallel version, and closing `psql` undoes the setting:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.441 ms

market=# EXPLAIN SELECT id, placed_at, total_cents FROM orders ORDER BY placed_at LIMIT 10;
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Limit  (cost=0.43..0.77 rows=10 width=20)
   ->  Index Scan using orders_placed_at_idx on orders  (cost=0.43..68618.43 rows=2000000 width=20)
(2 rows)

Time: 1.928 ms

market=# EXPLAIN SELECT id, placed_at, total_cents FROM orders ORDER BY total_cents LIMIT 10;
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Limit  (cost=79886.28..79886.31 rows=10 width=20)
   ->  Sort  (cost=79886.28..84886.28 rows=2000000 width=20)
         Sort Key: total_cents
         ->  Seq Scan on orders  (cost=0.00..36667.00 rows=2000000 width=20)
(4 rows)

Time: 0.716 ms
```

The first plan walks the index on `placed_at` from the start. That index scan, run to the end,
would return all two million orders at a total cost of `68618.43`. But its startup cost is `0.43`
— the first row comes out almost immediately, because the index is already in the order the query
wants — and the `Limit` above it stops asking after ten. So the planner charges the `Limit` ten
two-millionths of the scan: `0.43 + (68618.43 − 0.43) × 10 / 2000000`, which is the `0.77` on its
line.

The second plan has no index on `total_cents` to walk, so it reads every order and sorts. **A sort
cannot hand up its first row until it has seen the last one**, because the last row read could be
the cheapest of all. So the `Sort` has a startup cost of `79886.28`, more than twice the total
cost of the whole scan underneath it, and the `Limit` inherits that startup. Ten rows wanted, and
the plan still pays for all two million before the first one appears.

The same question — ten orders — costs `0.77` one way and `79886.31` the other, and the
difference is not in the `LIMIT` but in whether something below it can stop early. That is why
the planner looks at the startup cost whenever the query only wants the first rows: a `LIMIT`, an
`EXISTS`, a cursor fetching a page at a time. A plan with a high total and a low startup can win
those, and a plan with a high startup never can.

## What to take into the next section

- **Every node carries a prediction**: cost from start to finish, rows, width.
- **`EXPLAIN` alone runs nothing**, including a `DELETE`.
- **A node with a startup cost close to its total is a node that has to finish before it can
  start** — a sort, a hash being built, an aggregate. Spotting those is half of reading a plan.
