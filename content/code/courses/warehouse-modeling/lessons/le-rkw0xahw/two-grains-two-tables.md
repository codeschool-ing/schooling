---
title: Two grains, two tables
version: 1
---

Payments have their own grain. Most orders are paid once; some are paid with a gift card and a card
together, and get two payments. That is why `fact_payments` is a separate table, at one row per
payment, rather than columns on the sales lines.

The temptation is to join the two whenever a question involves both: revenue against money received,
say. Both tables carry the order number, so the join is one line:

```sql
-- Two fact tables at two grains, joined on the order number.
SELECT (SELECT sum(net_cents) FROM fact_sales)                    AS sold,
       (SELECT sum(amount_cents) FROM fact_payments)              AS paid,
       sum(s.net_cents)                                           AS sold_after_join,
       sum(p.amount_cents)                                        AS paid_after_join
FROM fact_sales s JOIN fact_payments p USING (order_id);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fan-out.sql
┌────────────┬────────────┬─────────────────┬─────────────────┐
│    sold    │    paid    │ sold_after_join │ paid_after_join │
│   int128   │   int128   │     int128      │     int128      │
├────────────┼────────────┼─────────────────┼─────────────────┤
│ 9574389852 │ 9799636132 │      9811600086 │     20368271993 │
└────────────┴────────────┴─────────────────┴─────────────────┘
```

Read the first two numbers. The shop sold R$ 95,743,898.52 of books and received R$ 97,996,361.32. The
difference is exactly the R$ 2,252,462.80 of shipping, which is paid but is not a book. Both totals are
right.

Then the join. **Sales grew by R$ 2,372,102.34 and payments more than doubled, to R$ 203,682,719.93.** An
order with three lines and one payment repeats the payment three times; an order with one line and two
payments repeats the line twice; an order with three lines and two payments produces six rows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One order with three lines and two payments. Joined on the order number, each of the three lines meets each of the two payments, and six rows come out: every line appears twice and every payment three times. Summing either column of the six rows overstates it.\"><defs><marker id=\"ah-fan-out\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales: 3 lines</text><text x=\"90\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">fact_payments: 2 payments</text><rect x=\"20\" y=\"36\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">line 1</text><rect x=\"20\" y=\"74\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">line 2</text><rect x=\"20\" y=\"112\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">line 3</text><rect x=\"20\" y=\"186\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payment 1</text><rect x=\"20\" y=\"224\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">payment 2</text><text x=\"395\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">joined on order_id: 6 rows</text><rect x=\"250\" y=\"36\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">line 1</text><text x=\"400\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">payment 1</text><rect x=\"250\" y=\"72\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">line 1</text><text x=\"400\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">payment 2</text><rect x=\"250\" y=\"108\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">line 2</text><text x=\"400\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">payment 1</text><rect x=\"250\" y=\"144\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">line 2</text><text x=\"400\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">payment 2</text><rect x=\"250\" y=\"180\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">line 3</text><text x=\"400\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">payment 1</text><rect x=\"250\" y=\"216\" width=\"290\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">line 3</text><text x=\"400\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">payment 2</text><line x1=\"165\" y1=\"135\" x2=\"240\" y2=\"135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah-fan-out)\"></line><text x=\"630\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">each line ×2</text><text x=\"630\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">each payment ×3</text><text x=\"630\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sum each to the order</text><text x=\"630\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first, then join</text></svg>", "caption": "Fan-out: joining two fact tables at different grains repeats each row of one for every matching row of the other."}
```

This is called **fan-out**, and it is what happens whenever two tables at different grains are joined
on a key that is not unique in either.

**The rule is the one drilling across used in lesson 3: sum each fact table to a common grain first,
then join.** Here the common grain is the order. Sum the lines per order, sum the payments per order,
and join one row to one row. Never join two fact tables row to row.
