---
title: Reading the tree from the inside out
version: 1
---

A plan is printed top to bottom, and the natural thing is to read it that way, as a recipe whose
first line is the first step. **It is the other way round: the first line is the last thing that
happens.** The deepest, most indented nodes run first, and rows flow upwards from them to the top,
which is where the answer leaves the server.

## The seller dashboard

Lesson 2's seller dashboard is December's orders for one seller, day by day. After that lesson's
index on `seller_id` it is no longer the workload's biggest cost. Its plan is still the best tree in
the workload to learn on: six nodes, and one of them has two children.

```
market=# EXPLAIN SELECT date_trunc('day', placed_at) AS day, count(*), sum(total_cents) FROM orders WHERE seller_id = 42 AND placed_at >= '2025-12-01' GROUP BY 1 ORDER BY 1;
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2287.58..2289.36 rows=79 width=24)
   Group Key: (date_trunc('day'::text, placed_at))
   ->  Sort  (cost=2287.58..2287.78 rows=79 width=12)
         Sort Key: (date_trunc('day'::text, placed_at))
         ->  Bitmap Heap Scan on orders  (cost=1984.02..2285.09 rows=79 width=12)
               Recheck Cond: ((seller_id = 42) AND (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone))
               ->  BitmapAnd  (cost=1984.02..1984.02 rows=79 width=0)
                     ->  Bitmap Index Scan on orders_seller_id_idx  (cost=0.00..19.61 rows=1491 width=0)
                           Index Cond: (seller_id = 42)
                     ->  Bitmap Index Scan on orders_placed_at_idx  (cost=0.00..1964.12 rows=106093 width=0)
                           Index Cond: (placed_at >= '2025-12-01 00:00:00-03'::timestamp with time zone)
(11 rows)

Time: 2.460 ms
```

Read it from the most indented lines outwards:

1. **`Bitmap Index Scan on orders_seller_id_idx`** walks the index lesson 2 built and marks every
   page of `orders` that holds one of seller 42's orders. About 1491 entries, it expects.
2. **`Bitmap Index Scan on orders_placed_at_idx`**, its sibling at the same indentation, does the
   same for every order placed since the first of December: 106093 entries.
3. **`BitmapAnd`** is the parent of both. It keeps only the pages marked twice — seller 42 *and*
   December — and expects 79 rows to survive.
4. **`Bitmap Heap Scan on orders`** visits those pages, reads the rows, and checks the condition
   again on each row (`Recheck Cond`), because a mark on a page says the page holds a match, not
   which row it is.
5. **`Sort`** puts the 79 rows in order of their day.
6. **`GroupAggregate`** walks the sorted rows and emits one row per day, with the count and the sum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"The seller dashboard&#x27;s plan drawn as a tree. At the bottom, two Bitmap Index Scans run first: on orders_seller_id_idx, expecting 1491 rows at a cost of 19.61, and on orders_placed_at_idx, expecting 106093 rows at a cost of 1964.12, which is most of the plan. Both feed a BitmapAnd, expecting 79 rows; above it the Bitmap Heap Scan on orders, own cost 301.07; then the Sort, own cost 2.69; and at the top the GroupAggregate, own cost 1.58, total 2289.36. Rows flow upwards and the order of execution is numbered from 1 at the bottom to 6 at the top.\"><text x=\"14\" y=\"16\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Run from the bottom up: the numbers are the order of execution</text><rect x=\"182\" y=\"36\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"57.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"57.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">6</text><text x=\"192\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GroupAggregate</text><text x=\"192\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own 1.58 of 2289.36</text><rect x=\"182\" y=\"102\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"123.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"123.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">5</text><text x=\"192\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Sort</text><text x=\"192\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own 2.69 of 2287.78</text><rect x=\"182\" y=\"168\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"189.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"189.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">4</text><text x=\"192\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bitmap Heap Scan on orders</text><text x=\"192\" y=\"199\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own 301.07 of 2285.09</text><rect x=\"182\" y=\"234\" width=\"240\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"168\" cy=\"255.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"168\" y=\"255.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">3</text><text x=\"192\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BitmapAnd</text><text x=\"192\" y=\"265\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own 0.29 of 1984.02</text><rect x=\"40\" y=\"300\" width=\"262\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><circle cx=\"26\" cy=\"321.0\" r=\"10\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"26\" y=\"321.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">1</text><text x=\"50\" y=\"314\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bitmap Index Scan on orders_seller_id_idx</text><text x=\"50\" y=\"331\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own 19.61 of 19.61</text><rect x=\"342\" y=\"300\" width=\"262\" height=\"42\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"328\" cy=\"321.0\" r=\"10\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"328\" y=\"321.5\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--ink)\">2</text><text x=\"352\" y=\"314\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bitmap Index Scan on orders_placed_at_idx</text><text x=\"352\" y=\"331\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">own 1964.12 of 1964.12</text><path d=\"M302.0 102 L302.0 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M302.0 78.0 L306.0 84.0 L298.0 84.0 Z\" fill=\"var(--wire)\"></path><text x=\"310.0\" y=\"90.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=79</text><path d=\"M302.0 168 L302.0 144\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M302.0 144.0 L306.0 150.0 L298.0 150.0 Z\" fill=\"var(--wire)\"></path><text x=\"310.0\" y=\"156.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=79</text><path d=\"M302.0 234 L302.0 210\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M302.0 210.0 L306.0 216.0 L298.0 216.0 Z\" fill=\"var(--wire)\"></path><text x=\"310.0\" y=\"222.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=79</text><path d=\"M171 300 L159 284 L272.0 284 L272.0 277\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M272.0 276 L268.0 282 L276.0 282 Z\" fill=\"var(--wire)\"></path><path d=\"M473 300 L461 284 L332.0 284 L332.0 277\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M332.0 276 L328.0 282 L336.0 282 Z\" fill=\"var(--wire)\"></path><text x=\"52\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=1491</text><text x=\"488\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">rows=106093</text><text x=\"440\" y=\"57\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the top line is the last step,</text><text x=\"440\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and its cost is the whole plan's</text><text x=\"440\" y=\"189\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own cost = total minus children</text><text x=\"616\" y=\"312\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">86% of</text><text x=\"616\" y=\"326\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the plan</text></svg>", "caption": "The dashboard's plan as a tree. Execution starts at the leaves and rows travel up; each box shows the node's own cost, its total minus its children's."}
```

## How the rows travel

The executor does not run the bottom node to completion and then the next one up. It asks the
top node for a row; that node asks its child for one, and so on down to a scan, which reads just
enough to produce it. Rows are **pulled**, one at a time, from the top. That is why the `Limit` in
the previous section could stop an index scan after ten rows: it simply stopped asking.

The pull explains the startup costs too. A `Sort` asked for its first row has to pull every row
from below before it can answer, so it does all its children's work up front. The
`GroupAggregate` here starts at `2287.58`, the same as the sort under it, because it can do nothing
until the sort has started handing rows up.

## Costs are cumulative, so subtract

**Every node's cost includes the cost of everything under it.** The top line, `2289.36`, is the
price of the whole query, not of the aggregate. To find which node is expensive, take each node's
total and subtract its children's totals:

| node | total | its children | its own |
|---|---|---|---|
| `GroupAggregate` | 2289.36 | 2287.78 | 1.58 |
| `Sort` | 2287.78 | 2285.09 | 2.69 |
| `Bitmap Heap Scan` | 2285.09 | 1984.02 | 301.07 |
| `BitmapAnd` | 1984.02 | 19.61 + 1964.12 | 0.29 |
| index scan on `seller_id` | 19.61 | — | 19.61 |
| index scan on `placed_at` | 1964.12 | — | 1964.12 |

**Eighty-six percent of the plan's cost is one node**: walking the 106093 index entries for
December, to throw away all but the 79 that are also seller 42's. The seller's own index costs
19.61. Nothing above the bitmap is worth looking at. A single index on both columns would let the
server go straight to seller 42's December; lessons 8 to 10 are about choosing indexes like that,
and this table is how you would know where to point one.

Subtracting is the habit to keep. A slow plan has a long top line by construction, so the top
line tells you nothing about where the time went. The node whose **own** share is large is the
one to look at.

## The two estimates that make the third

The 79 in the middle of the tree is a calculation, and it shows what the planner assumes. It
expected 1491 of the two million orders to be seller 42's and 106093 to be December's. Treating
the two conditions as unrelated, the share that meets both is the product of the two shares:

```
2000000 × (1491 / 2000000) × (106093 / 2000000) = 79.1
```

**The planner assumes conditions are independent unless told otherwise.** Here that is roughly
true — a seller's share of December is about its share of the year — and the estimate holds up.
For two columns that move together, such as a customer's city and state, the product is far too
small; lesson 7 shows that failure and the statistics that cure it.

## The detail lines

The lines without an arrow belong to the node above them, and four kinds appear in most plans:

| line | what it says |
|---|---|
| `Index Cond` | the condition the index answered: only matching entries were read |
| `Filter` | a condition checked on each row **after** it was read; the rows it removes were paid for |
| `Recheck Cond` | a bitmap scan checking each row again on the pages it was sent to |
| `Sort Key`, `Group Key` | what the node orders or groups by |

`sql-databases` lesson 10 named the one to look for first: a column you expected an index to
handle, sitting in a `Filter` line with no `Index Cond` naming it.
