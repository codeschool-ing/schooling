---
title: The order number, a dimension with no table
version: 1
---

`fact_sales` keeps `order_id`, and no dimension table goes with it.

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS lines, count(DISTINCT order_id) AS orders FROM fact_sales"
┌────────┬────────┐
│ lines  │ orders │
│ int64  │ int64  │
├────────┼────────┤
│ 887477 │ 572439 │
└────────┴────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT f.line_no, b.title, f.quantity, f.net_cents FROM fact_sales f JOIN dim_book b USING (book_key) WHERE f.order_id = 112406 ORDER BY f.line_no"
┌─────────┬──────────────────────┬──────────┬───────────┐
│ line_no │        title         │ quantity │ net_cents │
│  int64  │       varchar        │  int64   │   int64   │
├─────────┼──────────────────────┼──────────┼───────────┤
│       1 │ The Paper River VI   │        1 │      3290 │
│       2 │ The Bright River     │        1 │      2990 │
│       3 │ The Broken House III │        1 │      6890 │
└─────────┴──────────────────────┴──────────┴───────────┘
```

887,477 lines from 572,439 orders. Everything there is to say about an order is already said by the
other keys of its lines: the date, the shop, the customer, the promotion. A `dim_order` would be a
table of 572,439 rows with nothing in them but the order number, which is a table describing nothing.
So the number stays on the fact row and points nowhere.

Kimball calls that a **degenerate dimension**: a dimension key with no dimension behind it. It earns its
column for three reasons:

- **It groups the lines.** "Orders with more than three books" and "average books per order" are
  questions about the order, answered by grouping on its number.
- **It is the way back.** When a total looks wrong, somebody has to find the receipts behind it, and
  the order number is what the till printed on them.
- **It is the key to other grains.** Section 05 summed sales and payments per order. Without the order
  number on both, there would be nothing to sum by.

The same reasoning covers invoice numbers, ticket numbers and transaction ids: identifiers of the
event itself, kept on the fact row because the event has no description beyond what the fact
already carries.
