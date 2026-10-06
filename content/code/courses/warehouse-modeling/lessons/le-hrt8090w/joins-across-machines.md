---
title: Joins when the rows live apart
version: 1
---

A join of two rows can only happen on a node that holds both. In an MPP system each table is spread by
its own key, so the two sides of a join are usually on different nodes, and one of them has to move.
There are three ways it is done, and the planner picks one per join.

**Co-located: nothing moves.** If both tables are spread by the join key, matching rows are already on the
same node. Sales and payments, both spread by `order_id`, can be joined on `order_id` with no network
traffic at all.

**Broadcast: the small side is copied everywhere.** A dimension of a few thousand rows is sent whole to
every node, and each node joins its share of the fact table against its own copy.

**Shuffle: both sides are re-spread by the join key.** Every row is rehashed on the join key and sent to
the node that key belongs to. Expensive, because most rows move.

Here is the arithmetic for joining sales, spread by order, to books, spread by book, on four nodes:

```sql
-- Sales are spread by order. To join them with books spread by book, how
-- many rows would have to move? And to copy the whole book table to every
-- machine instead?
SELECT count(*) FILTER (WHERE hash(order_id) % 4 <> hash(book_key) % 4) AS sales_rows_moved,
       count(*)                                                          AS sales_rows,
       (SELECT count(*) * 3 FROM dim_book)                               AS book_rows_copied
FROM fact_sales;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < movement.sql
┌──────────────────┬────────────┬──────────────────┐
│ sales_rows_moved │ sales_rows │ book_rows_copied │
│      int64       │   int64    │      int64       │
├──────────────────┼────────────┼──────────────────┤
│           666023 │     887477 │             9000 │
└──────────────────┴────────────┴──────────────────┘
```

**Re-spreading the sales by book would move 666,023 of 887,477 rows, three quarters of the table.** That is
what random placement on four nodes predicts: a row stays where it is one time in four. **Broadcasting the
book table moves 9,000 rows**: 3,000 books, copied to the three nodes that do not have them already.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three ways an MPP system joins sales to books across four nodes, with the rows each moves in this lab. Co-located: both tables spread by the join key, nothing moves. Broadcast: the 3,000-row book table copied to the three other nodes, 9,000 rows moved. Shuffle: the sales re-spread by book, 666,023 of 887,477 rows moved.\"><rect x=\"20\" y=\"30\" width=\"215\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"127\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">co-located</text><text x=\"127\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">both spread by the join key</text><rect x=\"40\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"86\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"132\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"178\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"127\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">0 rows move</text><rect x=\"255\" y=\"30\" width=\"215\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"362\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">broadcast</text><text x=\"362\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the small table copied to all</text><rect x=\"275\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"321\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"367\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"413\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><line x1=\"293\" y1=\"130\" x2=\"339\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><line x1=\"293\" y1=\"130\" x2=\"385\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><line x1=\"293\" y1=\"130\" x2=\"431\" y2=\"130\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></line><text x=\"362\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">9,000 rows move</text><rect x=\"490\" y=\"30\" width=\"215\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"597\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">shuffle</text><text x=\"597\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the big table re-spread</text><rect x=\"510\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"556\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"602\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"648\" y=\"105\" width=\"36\" height=\"50\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><line x1=\"528\" y1=\"120\" x2=\"574\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"574\" y1=\"120\" x2=\"620\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"620\" y1=\"120\" x2=\"666\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"666\" y1=\"120\" x2=\"528\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"597\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">666,023 rows move</text></svg>", "caption": "Co-located, broadcast and shuffle, with the rows each would move between four nodes here."}
```

That difference is why the star schema suits MPP so well:

- **The fact table is spread by a key with many values**, for even shares.
- **The dimensions are small and broadcast**, or simply kept as a full copy on every node from the start.
  Redshift calls that `DISTSTYLE ALL`.
- **Joins between two large tables are the expensive case**, and the place to spend the distribution key:
  spread both by the key they are joined on, and they become co-located.
