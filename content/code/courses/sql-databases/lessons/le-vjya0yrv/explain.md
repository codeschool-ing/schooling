---
title: What EXPLAIN prints
version: 1
---

```sql
EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
```

Put `EXPLAIN` in front of a query and the database does not run it. It **plans** it — decides how
it would fetch the rows — and prints the decision. That decision is the plan, and every question in
this lesson is answered by reading one.

Here is the shop's `orders` table, a million rows, with the indexes lesson 9 left it: a primary
key and nothing on `customer_id`.

```
shop=# EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
                         QUERY PLAN                         
------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..19966.00 rows=11 width=28)
   Filter: (customer_id = 42)
(2 rows)
```

Two lines. The first is a **node**: a step the executor will perform, here a sequential scan of
`orders`, which means reading the table from the first page to the last. The second is a detail of
that node: as it reads, it keeps the rows where `customer_id = 42` and drops the rest. That is what
`Filter` means — a condition checked against each row **after** the row has been fetched.

## The four numbers

```
(cost=0.00..19966.00 rows=11 width=28)
```

**`cost` is two numbers, and neither is a time.** They are in the planner's own unit, where reading
one page from disk in sequence costs 1 by definition and everything else is priced relative to
that. The first is the cost before the node can return its first row; the second is the cost of
returning all of them. A sequential scan starts immediately — `0.00` — and finishes when the table
ends. The planner compares plans by these numbers and picks the cheapest. So when a plan looks
wrong, the cost is the first thing to ask about: **the planner thought this was the cheapest plan
available**, and either it was right or one of its numbers was.

**`rows` is how many the node expects to return.** Not how many it reads — how many survive to be
passed upwards. Eleven, here, for a million-row table: the planner knows from its statistics
roughly how many orders a customer has. This is an estimate, and the section on estimates is
entirely about what happens when it is wrong.

**`width` is the average size of one row in bytes**, which decides how much memory a sort or a
hash will need. Twenty-eight bytes for `SELECT *` from `orders`; ask for fewer columns and it drops.

## The same query, with an index to use

`customers.email` has a unique index, because lesson 9's constraint is an index:

```
shop=# EXPLAIN SELECT * FROM customers WHERE email = 'user42@example.com';
                                      QUERY PLAN                                      
--------------------------------------------------------------------------------------
 Index Scan using customers_email_key on customers  (cost=0.42..8.44 rows=1 width=56)
   Index Cond: (email = 'user42@example.com'::text)
(2 rows)
```

A different node — `Index Scan` — and a different second line. `Index Cond` is a condition the
index itself answered: the tree was descended to the entries for that address and only those rows
were fetched. `Filter`, above, is a condition applied to rows already in hand. The distinction is
the most useful thing to look for in a plan. It is what "the index is not used" looks like in
practice: **the column is in a `Filter` line, and there is no `Index Cond` naming it.**

The costs say the rest. `0.42..8.44` against `0.00..19966.00`: the index scan pays a small amount
to start — descending the tree — and is done after a handful of pages. The scan is free to start
and costs twenty thousand to finish.

## A plan is a tree, read from the inside out

Most queries need more than one step, and the steps nest:

```
shop=# EXPLAIN SELECT c.name, o.id, o.total FROM customers c JOIN orders o ON o.customer_id = c.id WHERE c.email = 'user42@example.com';
                                             QUERY PLAN                                             
----------------------------------------------------------------------------------------------------
 Hash Join  (cost=8.45..20099.56 rows=10 width=23)
   Hash Cond: (o.customer_id = c.id)
   ->  Seq Scan on orders o  (cost=0.00..17466.00 rows=1000000 width=14)
   ->  Hash  (cost=8.44..8.44 rows=1 width=17)
         ->  Index Scan using customers_email_key on customers c  (cost=0.42..8.44 rows=1 width=17)
               Index Cond: (email = 'user42@example.com'::text)
(6 rows)
```

Indentation is structure. `Hash Join` is the root; the two nodes marked `->` underneath it are its
**children**, and the `Index Scan` is a child of the `Hash`. Each node asks the nodes below it for
rows, does its own work, and hands rows to the node above. So the executor's first act is at the
bottom of the deepest branch, and the last is at the top.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"On the left, a plan as EXPLAIN prints it: a Hash Join at the top, with an arrow-marked Seq Scan on orders indented beneath it and an arrow-marked Hash beneath that, and an Index Scan on customers indented one level further under the Hash. On the right, the same plan drawn as a tree of boxes: the Hash Join box at the top, the Seq Scan box and the Hash box side by side below it, and the Index Scan box below the Hash. Arrows point upwards from each child box into its parent, and a note says that rows flow upwards. A second note beside the Index Scan box says it is the first node to run, and a third beside the Hash Join says it is the last, and the one whose rows the client receives.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">as EXPLAIN prints it</text>\n<text x=\"14\" y=\"52\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash Join</text>\n<text x=\"14\" y=\"70\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">  Hash Cond: (o.customer_id = c.id)</text>\n<text x=\"14\" y=\"88\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  -&gt;  Seq Scan on orders o</text>\n<text x=\"14\" y=\"106\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  -&gt;  Hash</text>\n<text x=\"14\" y=\"124\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">        -&gt;  Index Scan on customers c</text>\n<text x=\"14\" y=\"142\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">              Index Cond: (email = ...)</text>\n<text x=\"14\" y=\"180\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">indentation is the tree; -&gt; marks a child</text>\n<line x1=\"340\" y1=\"12\" x2=\"340\" y2=\"304\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"366\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the same plan, as a tree</text>\n<rect x=\"446\" y=\"40\" width=\"150\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"521\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash Join</text>\n<rect x=\"366\" y=\"134\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"431\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan orders</text>\n<rect x=\"546\" y=\"134\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"611\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash</text>\n<rect x=\"531\" y=\"228\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"611\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan customers</text>\n<path d=\"M431 134 L431 100 L521 100 L521 74\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M515 84 L521 74 L527 84\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M611 134 L611 100 L521 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M611 228 L611 168\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M605 178 L611 168 L617 178\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"366\" y=\"100\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">rows flow up</text>\n<text x=\"366\" y=\"245\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">runs first: deepest child</text>\n<text x=\"366\" y=\"290\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">runs last: the root, whose rows the client receives</text>\n</svg>", "caption": "The indented text and the tree are one structure. Each node pulls rows from its children and pushes them to its parent, so the deepest child runs first and the root finishes last."}
```

The join here is the one from lesson 5: one customer, found by email through the index, joined to
their orders. And the plan says something the query does not: to find thirteen orders it read
**all million** — `Seq Scan on orders`, with `rows=1000000` — and matched them against a hash of
one customer. That is the missing index on `orders.customer_id` from lesson 9, seen from the other
side. Nothing in the SQL is wrong; the plan is how you find out that the schema is.

## Other shapes of the same thing

`EXPLAIN` prints text because a person reads it. Tools read it too, and for them there is a
structured form:

```
shop=# EXPLAIN (FORMAT JSON) SELECT * FROM customers WHERE email = 'user42@example.com';
                         QUERY PLAN                         
------------------------------------------------------------
 [                                                         +
   {                                                       +
     "Plan": {                                             +
       "Node Type": "Index Scan",                          +
       "Parallel Aware": false,                            +
       "Async Capable": false,                             +
       "Scan Direction": "Forward",                        +
       "Index Name": "customers_email_key",                +
       "Relation Name": "customers",                       +
       "Alias": "customers",                               +
       "Startup Cost": 0.42,                               +
       "Total Cost": 8.44,                                 +
       "Plan Rows": 1,                                     +
       "Plan Width": 56,                                   +
       "Index Cond": "(email = 'user42@example.com'::text)"+
     }                                                     +
   }                                                       +
 ]
(1 row)
```

Same plan, every field named. `EXPLAIN (FORMAT JSON)` is what a plan visualiser consumes, and it is
worth knowing the names — `Plan Rows`, `Total Cost` — because they are the same things as the text,
and a visualiser that draws a red box is drawing one of these numbers.

## What EXPLAIN alone cannot tell you

Everything above is a prediction. The rows are estimated, the costs are estimated, and the query
never ran. A plan can look perfect and be slow, because the planner was working from numbers that
were wrong — and finding that out needs the query to actually execute, which is the next section.
