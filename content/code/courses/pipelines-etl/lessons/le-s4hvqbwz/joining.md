---
title: Joining, and the rows that multiply
version: 1
---

A join is where a transformation most often goes wrong without an error, and it always goes wrong
the same way. **Revenue is on the payment, one per order. Books are on the lines, several per
order.** Join the two to get both in one query, and every payment is repeated once per line:

```
ana@vm:~/etl$ psql -d wh -c "SELECT sum(p.amount_cents) AS revenue_cents FROM raw.orders o JOIN raw.payments p USING (order_id) WHERE o.status = 'completed'"
 revenue_cents 
---------------
     212162290
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT sum(p.amount_cents) AS revenue_cents FROM raw.orders o JOIN raw.payments p USING (order_id) JOIN raw.order_lines l USING (order_id) WHERE o.status = 'completed'"
 revenue_cents 
---------------
     417391350
(1 row)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS orders, (SELECT count(*) FROM raw.orders o JOIN raw.order_lines l USING (order_id) WHERE o.status = 'completed') AS after_the_join FROM raw.orders WHERE status = 'completed'"
 orders | after_the_join 
--------+----------------
  18608 |          29152
(1 row)
```

The first query adds up payments for completed orders: R$ 2,121,622.90. The second adds the lines
to the join and adds up the same column — and gets R$ 4,173,913.50, almost twice as much, because
an order with three lines now has its payment three times. The third query says it in rows: 18,608
orders became 29,152 rows after the join, and the picture below is one of them.



```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l06-fanout\" aria-label=\"One order with three lines and one payment of R$ 159.70. Joined, the result has three rows, each carrying the same payment, so a sum of the payment column says R$ 479.10 for an order that was paid R$ 159.70.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40.0\" y=\"40.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">order 1</text><text x=\"125.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 payment: R$ 159.70</text><rect x=\"60.0\" y=\"120.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">line 1</text><rect x=\"60.0\" y=\"160.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">line 2</text><rect x=\"60.0\" y=\"200.0\" width=\"130.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">line 3</text><text x=\"125.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 lines</text><text x=\"470.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">after the join</text><rect x=\"330.0\" y=\"50.0\" width=\"280.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">line 1</text><text x=\"595.0\" y=\"64.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 159.70</text><path d=\"M192.0 134.0 L328.0 64.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"330.0\" y=\"90.0\" width=\"280.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">line 2</text><text x=\"595.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 159.70</text><path d=\"M192.0 174.0 L328.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"330.0\" y=\"130.0\" width=\"280.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">line 3</text><text x=\"595.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">R$ 159.70</text><path d=\"M192.0 214.0 L328.0 144.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"330.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sum of the payment column</text><text x=\"610.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">R$ 479.10</text><text x=\"330.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what was paid</text><text x=\"610.0\" y=\"214.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R$ 159.70</text></svg>", "caption": "The join goes down from the order to its lines, and everything at order grain is repeated once per line."}
```

This is called **fan-out**, and it has three properties that make it dangerous:

- nothing fails — the SQL is valid and the number is plausible;
- it depends on the data — on a day when every order has one line, the totals are right, and
  the bug appears on the first busy Saturday;
- it hides in aggregates — the joined rows are never looked at, only their sum.

## The rule that prevents it

**Know the grain of every table, and never aggregate a column from a table whose rows the join has
multiplied.** The grain of `payments` is one row per order; the grain of `order_lines` is one row per
line. Joining them produces a table at line grain, and anything at order grain — the payment
amount — is now repeated. So either:

- sum at the grain the column lives at — revenue from lines as `quantity * unit_price_cents`, which
  belongs to the line; or
- aggregate each side to a common grain first, and then join.

And check it the cheap way, every time a join is added: **count the rows before and after.** If the
count changes and you did not expect it to, the join has fanned out. That one comparison is the
whole of the third query above.
