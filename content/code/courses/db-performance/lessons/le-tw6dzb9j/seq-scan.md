---
title: The sequential scan, and why it is not the enemy
version: 1
---

Every plan bottoms out in nodes that read a table, and PostgreSQL has three main ways to do it.
This lesson takes them one at a time on `orders`, and then asks the question that decides between
them: how many of the table's rows does the query want, and how far apart do they sit?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Three ways to read the same twelve pages of a table, four of which hold matching rows. Seq Scan reads all twelve pages from left to right. Index Scan follows six index entries in index order to their pages, jumping back and forth and visiting two pages twice. Bitmap Heap Scan first turns the entries into one mark per page, then visits the four marked pages once each, from left to right.\"><text x=\"14\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"14\" y=\"88\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every page, in order</text><text x=\"14\" y=\"106\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">12 pages read</text><rect x=\"230\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"245.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><rect x=\"268\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><rect x=\"306\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><rect x=\"344\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"359.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><rect x=\"382\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"397.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><rect x=\"420\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><rect x=\"458\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"473.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><rect x=\"496\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><rect x=\"534\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"549.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9</text><rect x=\"572\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"587.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10</text><rect x=\"610\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"625.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">11</text><rect x=\"648\" y=\"74\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"663.0\" y=\"89.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">12</text><path d=\"M235.0 118 L673.0 118\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M673.0 118.0 L667.0 122.0 L667.0 114.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"14\" y=\"198\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan</text><text x=\"14\" y=\"216\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">entry by entry, in index order</text><text x=\"14\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 visits, 2 pages twice</text><rect x=\"230\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"245.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><rect x=\"268\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><rect x=\"306\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><rect x=\"344\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"359.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><rect x=\"382\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"397.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><rect x=\"420\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><rect x=\"458\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"473.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><rect x=\"496\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><rect x=\"534\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"549.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9</text><rect x=\"572\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"587.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10</text><rect x=\"610\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"625.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">11</text><rect x=\"648\" y=\"202\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"663.0\" y=\"217.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">12</text><rect x=\"270\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"288\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><path d=\"M288 174 L587.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M587.0 201.0 L580.7 204.4 L581.4 196.5 Z\" fill=\"var(--phosphor)\"></path><rect x=\"320\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"338\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">2</text><path d=\"M338 174 L321.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M321.0 201.0 L320.8 193.8 L327.6 198.1 Z\" fill=\"var(--phosphor)\"></path><rect x=\"370\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"388\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">3</text><path d=\"M388 174 L473.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M473.0 201.0 L466.1 203.0 L468.5 195.4 Z\" fill=\"var(--phosphor)\"></path><rect x=\"420\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"438\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">4</text><path d=\"M438 174 L321.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M321.0 201.0 L325.9 195.8 L327.7 203.5 Z\" fill=\"var(--phosphor)\"></path><rect x=\"470\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"488\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">5</text><path d=\"M488 174 L435.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M435.0 201.0 L438.5 194.7 L442.2 201.8 Z\" fill=\"var(--phosphor)\"></path><rect x=\"520\" y=\"156\" width=\"36\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\"></rect><text x=\"538\" y=\"165\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--phosphor)\">6</text><path d=\"M538 174 L587.0 201\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M587.0 201.0 L579.8 201.6 L583.7 194.6 Z\" fill=\"var(--phosphor)\"></path><text x=\"14\" y=\"326\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bitmap Heap Scan</text><text x=\"14\" y=\"344\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mark the pages, then visit them</text><text x=\"14\" y=\"362\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4 pages, once each, in order</text><rect x=\"230\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"245.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><rect x=\"268\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"283.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><rect x=\"306\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><rect x=\"344\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"359.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><rect x=\"382\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"397.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><rect x=\"420\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"435.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><rect x=\"458\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"473.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><rect x=\"496\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><rect x=\"534\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"549.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">9</text><rect x=\"572\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"587.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10</text><rect x=\"610\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"625.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">11</text><rect x=\"648\" y=\"330\" width=\"30\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"663.0\" y=\"345.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">12</text><text x=\"245.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"283.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"321.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"359.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"397.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"435.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"473.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"511.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"549.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"587.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--phosphor)\">1</text><text x=\"625.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><text x=\"663.0\" y=\"300\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0</text><path d=\"M321.0 308 L321.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M321.0 329.0 L317.0 323.0 L325.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M435.0 308 L435.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M435.0 329.0 L431.0 323.0 L439.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M473.0 308 L473.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M473.0 329.0 L469.0 323.0 L477.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M587.0 308 L587.0 329\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></path><path d=\"M587.0 329.0 L583.0 323.0 L591.0 323.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M321.0 374 L587.0 374\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M593.0 374 L587.0 370 L587.0 378 Z\" fill=\"var(--phosphor)\"></path></svg>", "caption": "The three access paths over the same pages. Outlined pages hold a matching row."}
```

The belief to drop first is that a sequential scan in a plan is a mistake. People learn "add an
index" before they learn anything else about performance, and from then on a `Seq Scan` looks like
the index that was forgotten. **For a query that wants a large part of a table, reading the whole
table in order is the fastest plan there is**, and the planner is usually right to choose it.

## What it does

A sequential scan reads the table's pages from the first to the last, in the order they sit in the
file, and checks every row against the condition. Lesson 3 priced it: one `seq_page_cost` per page
and one `cpu_tuple_cost` per row, plus one `cpu_operator_cost` per condition per row. There is no
index involved and nothing to start up.

Count the orders worth more than 400 reais, with parallel plans off for the session so that the
plain node shows:

```
market=# SET max_parallel_workers_per_gather = 0;
SET
Time: 0.411 ms

market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE total_cents > 40000;
                                                      QUERY PLAN                                                      
----------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=42725.62..42725.63 rows=1 width=8) (actual time=237.817..237.819 rows=1 loops=1)
   Buffers: shared hit=2208 read=14459
   ->  Seq Scan on orders  (cost=0.00..41667.00 rows=423449 width=0) (actual time=0.032..212.163 rows=419881 loops=1)
         Filter: (total_cents > 40000)
         Rows Removed by Filter: 1580119
         Buffers: shared hit=2208 read=14459
 Planning:
   Buffers: shared hit=111
 Planning Time: 0.571 ms
 Execution Time: 237.956 ms
(10 rows)

Time: 240.535 ms
```

**All 16667 pages, 2208 found in memory and 14459 read**, and 1580119 rows removed by the filter to
keep 419881. Those removed rows are the cost of a `Filter` line, and here they are the right cost
to pay. The query wants one order in five, and prices are spread at random through the table, so
with about 120 orders to a page nearly every page holds at least one that matches. There is no
smaller set of pages that contains the answer.

Reading in order is what makes it cheap. The disk and the operating system both see the pages
asked for one after another, and read ahead of the request; PostgreSQL's own ring of buffers,
which lesson 3 met, keeps the scan from pushing everybody else's pages out of memory. **A
sequential scan is the plan whose cost per page is lowest**, and its weakness is only that it
cannot skip any.

## The parallel version

Now the same count with parallel plans allowed again, which is how the server ships:

```
market=# EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders WHERE total_cents > 40000;
                                                                QUERY PLAN                                                                
------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=28524.97..28524.98 rows=1 width=8) (actual time=88.653..92.648 rows=1 loops=1)
   Buffers: shared hit=2240 read=14427
   ->  Gather  (cost=28524.76..28524.97 rows=2 width=8) (actual time=88.478..92.636 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         Buffers: shared hit=2240 read=14427
         ->  Partial Aggregate  (cost=27524.76..27524.77 rows=1 width=8) (actual time=85.473..85.474 rows=1 loops=3)
               Buffers: shared hit=2240 read=14427
               ->  Parallel Seq Scan on orders  (cost=0.00..27083.67 rows=176437 width=0) (actual time=0.035..76.587 rows=139960 loops=3)
                     Filter: (total_cents > 40000)
                     Rows Removed by Filter: 526706
                     Buffers: shared hit=2240 read=14427
 Planning:
   Buffers: shared hit=114
 Planning Time: 0.518 ms
 Execution Time: 92.759 ms
(16 rows)

Time: 94.262 ms
```

Lesson 3 read the shape of this already. The `Parallel Seq Scan` is shared between three
processes, `loops=3`: each claims the next block of pages as it finishes the last, so the three
between them read every page once. Each counted its share — `rows=139960` on average, 419880 in
all, the same answer — and the `Partial Aggregate` above them is one count per process, which the
`Finalize Aggregate` adds up. **93 milliseconds instead of 238**, for the same 16667 pages.

Three processes did not make it three times faster. The `Gather` has to start the workers and
collect their rows, and the three compete for the same disk and memory. The planner prices that
too: its estimate of the scan's cost dropped from `41667.00` to `27083.67`, not to a third.

Two settings decide whether this happens at all. `max_parallel_workers_per_gather` is how many
helpers one node may have — 2 by default, which is what this plan launched. And a table has to be
big enough to be worth the start-up:

```
market=# SHOW min_parallel_table_scan_size;
 min_parallel_table_scan_size 
------------------------------
 8MB
(1 row)

Time: 0.508 ms

market=# SELECT pg_size_pretty(pg_relation_size('products'));
 pg_size_pretty 
----------------
 5192 kB
(1 row)

Time: 0.861 ms

market=# EXPLAIN SELECT count(*) FROM products WHERE price_cents > 20000;
                             QUERY PLAN                              
---------------------------------------------------------------------
 Aggregate  (cost=1351.25..1351.26 rows=1 width=8)
   ->  Seq Scan on products  (cost=0.00..1274.00 rows=30899 width=0)
         Filter: (price_cents > 20000)
(3 rows)

Time: 1.101 ms
```

`products` is about 5 MB, below the 8 MB of `min_parallel_table_scan_size`, so its scan stays a
single process whatever the query. **Parallelism is for large scans**; a small one finishes before
the helpers would have started.

## When a sequential scan is wrong

The plan is wrong when the scan reads a whole table to keep a handful of rows: a `Seq Scan` with a
`Rows Removed by Filter` in the millions and a `rows` in the tens. Lesson 1's count of seller 42's
orders was that shape — two million rows read to keep 1532 — and an index was the fix. Telling
that shape apart from the one above is the whole of this lesson, and it rests on a number the next
two sections put on the screen: how many **pages**, not rows, the answer is spread over.
