---
title: The nested loop, one lookup per row
version: 1
---

`sql-databases` lesson 5 said what a join means: rows of two tables paired on a condition. It
said nothing about how the server finds the pairs, and there are three ways. Each has a shape in
the plan, a kind of input it is good at, and a way of going wrong:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three panels. Nested Loop: each of four outer rows looks up its matches in an index on the inner table, one lookup per outer row, so the inner side runs once per row. Hash Join: first the smaller input is read whole into a hash table in memory, then the larger input streams past it once and each row probes the table. Merge Join: both inputs arrive sorted on the join key, and two pointers walk down them together, each list read once.\"><rect x=\"10\" y=\"10\" width=\"220\" height=\"250\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"22\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Nested Loop</text><rect x=\"250\" y=\"10\" width=\"220\" height=\"250\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"262\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hash Join</text><rect x=\"490\" y=\"10\" width=\"220\" height=\"250\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"502\" y=\"28\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Merge Join</text><rect x=\"24\" y=\"56\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o1</text><path d=\"M80 68 L138 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 68.0 L132.0 72.0 L132.0 64.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"24\" y=\"96\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o2</text><path d=\"M80 108 L138 108\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 108.0 L132.0 112.0 L132.0 104.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"24\" y=\"136\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"148\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o3</text><path d=\"M80 148 L138 148\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 148.0 L132.0 152.0 L132.0 144.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"24\" y=\"176\" width=\"56\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"52\" y=\"188\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">o4</text><path d=\"M80 188 L138 188\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M138.0 188.0 L132.0 192.0 L132.0 184.0 Z\" fill=\"var(--phosphor)\"></path><rect x=\"140\" y=\"56\" width=\"76\" height=\"144\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"178\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">index</text><text x=\"178\" y=\"134\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">of inner</text><text x=\"24\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">one lookup per outer row</text><rect x=\"264\" y=\"52\" width=\"80\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"304\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">small side</text><path d=\"M304 82 L304 104\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M304.0 104.0 L300.0 98.0 L308.0 98.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"352\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 build</text><rect x=\"264\" y=\"106\" width=\"80\" height=\"82\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"114\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"114\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"114\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"132\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"132\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"132\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"150\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"272\" y=\"168\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"296\" y=\"168\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320\" y=\"168\" width=\"18\" height=\"12\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"360\" y=\"106\" width=\"58\" height=\"140\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"389\" y=\"170\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">large</text><text x=\"389\" y=\"184\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">side</text><path d=\"M360 150 L346 150\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><path d=\"M346.0 150.0 L352.0 146.0 L352.0 154.0 Z\" fill=\"var(--amber)\"></path><text x=\"372\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">2 probe</text><text x=\"264\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">memory for one side</text><rect x=\"510\" y=\"50\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1</text><rect x=\"510\" y=\"78\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2</text><rect x=\"510\" y=\"106\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"117\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">3</text><rect x=\"510\" y=\"134\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">5</text><rect x=\"620\" y=\"50\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"61\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1</text><rect x=\"620\" y=\"78\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"89\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">1</text><rect x=\"620\" y=\"106\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"117\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">2</text><rect x=\"620\" y=\"134\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">3</text><rect x=\"620\" y=\"162\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">4</text><rect x=\"620\" y=\"190\" width=\"40\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"640\" y=\"201\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">5</text><path d=\"M552 61 L618 61\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 61 L618 89\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 89 L618 117\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 117 L618 145\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M552 145 L618 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><text x=\"504\" y=\"232\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">both sorted, each read once</text></svg>", "caption": "The three join algorithms. Nested loop pays per outer row, hash join pays memory for one side, merge join needs both sides in order."}
```

The planner picks one per join, from the row counts it expects on each side. This section and the
next two take them one at a time on `market`'s tables, with parallel plans off for the session as
in lessons 3 and 4, so each plan is one tree.

## The shape

A nested loop is the join anybody would write by hand:

```
for each row in the outer input:
    for each row in the inner input that matches it:
        emit the pair
```

The **outer** input is the node printed first under `Nested Loop`; the **inner** input is the
second, and it runs once for every row the outer one produces. That inner side is almost always
an index lookup — "find the rows whose key equals this outer row's key" — and when it is, the
cost of the join is the number of outer rows times the price of one lookup.

## One customer's orders and their lines

Customer 4242's orders, each with its lines:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.670 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT o.id, o.placed_at, l.product_id, l.quantity FROM orders AS o JOIN order_lines AS l ON l.order_id = o.id WHERE o.customer_id = 4242;
                                                               QUERY PLAN                                                                
-----------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=4.95..179.97 rows=27 width=24) (actual time=0.075..0.354 rows=24 loops=1)
   Buffers: shared hit=17 read=36
   ->  Bitmap Heap Scan on orders o  (cost=4.51..47.80 rows=11 width=16) (actual time=0.044..0.118 rows=10 loops=1)
         Recheck Cond: (customer_id = 4242)
         Heap Blocks: exact=10
         Buffers: shared hit=2 read=11
         ->  Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..4.51 rows=11 width=0) (actual time=0.032..0.032 rows=10 loops=1)
               Index Cond: (customer_id = 4242)
               Buffers: shared read=3
   ->  Index Scan using order_lines_pkey on order_lines l  (cost=0.43..11.98 rows=3 width=16) (actual time=0.022..0.023 rows=2 loops=10)
         Index Cond: (order_id = o.id)
         Buffers: shared hit=15 read=25
 Planning:
   Buffers: shared hit=313 read=6
 Planning Time: 1.175 ms
 Execution Time: 0.448 ms
(16 rows)

Time: 2.904 ms
```

Read it inside out, as lesson 3 taught. The outer side is the bitmap scan of `orders` that lesson 3
read on its own: ten orders for this customer. For each of them the inner side, an index scan of
`order_lines_pkey`, finds that order's lines: **`loops=10`**, and `rows=2` per loop, an average —
the join returned 24 lines in all, which is what the `Nested Loop` line says. The inner scan's
`actual time=0.022..0.023` is per loop too, so ten lookups took about a quarter of a millisecond
between them.

One number on that line is **not** per loop: `Buffers`. The inner scan's 40 pages (15 hit, 25 read)
are the total over all ten lookups, four pages each — a few levels of the index and the page of
the table holding the order's lines. Lesson 3's rule, multiply by `loops`, applies to the times and
the rows, which are averages, and not to the buffers, which are already summed.

**Half a millisecond for the whole join.** For ten outer rows nothing else comes close: a hash join
would have had to read one of the two tables whole before producing anything.

## When it goes wrong

The nested loop's cost grows with the number of outer rows, and the planner chose it here because
it expected eleven. Each lookup cost about 0.022 milliseconds; a hundred thousand of them would be
two seconds of lookups, plus the pages they touch scattered across the table, as lesson 4 showed
an index scan on an uncorrelated column does. The shape to recognise in a slow plan is therefore:

- a **`Nested Loop`** whose inner child has a **`loops`** in the tens of thousands or more,
- and an outer child whose **estimated** rows were small, against **actual** rows that were not.

The second line is the dangerous part. A nested loop chosen for 10 outer rows that receives 100000
is the commonest bad plan there is, and the join is not the cause — the estimate is. Lesson 6
reproduces exactly that, and section 05 of this lesson shows the planner moving away from a nested
loop as the expected outer side grows.

The other bad shape is an inner side with no index to use: a nested loop over a sequential scan
reads the whole inner table once per outer row. The planner avoids it whenever there is any
alternative, so when you see one, an index on the join column is usually what is missing.
