---
title: Facts: what was measured
version: 1
---

A **fact table** holds measurements of a business process, one row per event at the declared
grain. Its columns are of two kinds only: **keys** pointing at dimensions, and **measures**, the
numbers.

Ana's first one records selling books:

```sql
-- The first fact table. Grain: one row per line of an order that was not
-- cancelled. Lesson 4 adds the customer.
CREATE TABLE fact_sales AS
SELECT d.date_key,
       s.shop_key,
       b.book_key,
       coalesce(l.promotion_id, 0)                        AS promotion_key,
       o.order_id,
       l.line_no,
       l.quantity,
       l.quantity * l.unit_price_cents                    AS gross_cents,
       l.discount_cents,
       l.quantity * l.unit_price_cents - l.discount_cents AS net_cents
FROM staging.order_lines l
JOIN staging.orders o USING (order_id)
JOIN dim_date d       ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s       ON s.shop_id = o.shop_id
JOIN dim_book b       ON b.book_id = l.book_id
WHERE o.status <> 'cancelled'
ORDER BY o.order_id, l.line_no;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < fact_sales.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM fact_sales LIMIT 3"
┌──────────┬──────────┬──────────┬───────────────┬──────────┬─────────┬──────────┬─────────────┬────────────────┬───────────┐
│ date_key │ shop_key │ book_key │ promotion_key │ order_id │ line_no │ quantity │ gross_cents │ discount_cents │ net_cents │
│  int32   │  int64   │  int64   │     int64     │  int64   │  int64  │  int64   │    int64    │     int64      │   int64   │
├──────────┼──────────┼──────────┼───────────────┼──────────┼─────────┼──────────┼─────────────┼────────────────┼───────────┤
│ 20240101 │        5 │     2988 │             0 │   100001 │       1 │        1 │       11390 │              0 │     11390 │
│ 20240101 │        5 │     2958 │             0 │   100002 │       1 │        1 │        6190 │              0 │      6190 │
│ 20240101 │        5 │     1332 │             0 │   100003 │       1 │        1 │        9790 │              0 │      9790 │
└──────────┴──────────┴──────────┴───────────────┴──────────┴─────────┴──────────┴─────────────┴────────────────┴───────────┘
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS lines, sum(net_cents) AS net_cents FROM fact_sales"
┌────────┬────────────┐
│ lines  │ net_cents  │
│ int64  │   int128   │
├────────┼────────────┤
│ 887477 │ 9574389852 │
└────────┴────────────┘
```

Read the first row from left to right. On 1 January 2024 (`date_key`), at the shop with key 5
(`Online`), the book with key 2988 was sold with no promotion (`promotion_key` 0), as line 1 of order 100001:
one copy, R$ 113.90, no discount. **Every column is either a pointer to context or a number**, and
that is all a fact row is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"The first star. In the middle, fact_sales with its keys date_key, shop_key, book_key and promotion_key, the order number and line, and the measures quantity, gross_cents, discount_cents and net_cents. Around it four dimensions, each joined by one key: dim_date with the year, month, weekday and holiday; dim_shop with the name, city, state, region and channel; dim_book with the title, authors, format, category, subcategory, department and publisher; and dim_promotion with the code, name and percentage.\"><line x1=\"360\" y1=\"200\" x2=\"95.0\" y2=\"61.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"200\" x2=\"625.0\" y2=\"61.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"200\" x2=\"95.0\" y2=\"296.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"360\" y1=\"200\" x2=\"625.0\" y2=\"303.5\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"265.0\" y=\"121.5\" width=\"190\" height=\"157\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"134.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales</text><text x=\"275.0\" y=\"151.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">date_key</text><text x=\"275.0\" y=\"166.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_key</text><text x=\"275.0\" y=\"181.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">book_key</text><text x=\"275.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">promotion_key</text><text x=\"275.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">order_id, line_no</text><text x=\"275.0\" y=\"226.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">quantity</text><text x=\"275.0\" y=\"241.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">gross_cents</text><text x=\"275.0\" y=\"256.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">discount_cents</text><text x=\"275.0\" y=\"271.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">net_cents</text><rect x=\"20\" y=\"20\" width=\"150\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_date</text><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">date_key</text><text x=\"30\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">year, month</text><text x=\"30\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">day_name</text><text x=\"30\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">is_holiday</text><rect x=\"550\" y=\"20\" width=\"150\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_shop</text><text x=\"560\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_key</text><text x=\"560\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_name, city</text><text x=\"560\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">state, region</text><text x=\"560\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">channel</text><rect x=\"20\" y=\"255\" width=\"150\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_book</text><text x=\"30\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">book_key</text><text x=\"30\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">title, authors</text><text x=\"30\" y=\"315\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">category … department</text><text x=\"30\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">publisher</text><rect x=\"550\" y=\"270\" width=\"150\" height=\"67\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"283\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">dim_promotion</text><text x=\"560\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">promotion_key</text><text x=\"560\" y=\"315\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">code, name</text><text x=\"560\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">percent_off</text><text x=\"360\" y=\"380\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">keys point outwards; measures stay in the middle</text></svg>", "caption": "The first star schema: one fact table of order lines, and four dimensions one join away."}
```

Four things in that `CREATE` are decisions rather than mechanics:

- **The grain is written in the first comment.** One row per line of an order that was not
  cancelled. Each line is one book, so `book_key` has exactly one value per row, which is the test
  a dimension has to pass.
- **Cancelled orders are left out here, once.** Lesson 1's report had to remember `status <>
  'cancelled'`; nothing that reads this table can forget it.
- **The measures are computed here, once.** `net_cents` is quantity times price minus discount.
  Two analysts who would have written that formula two ways now read the same column.
- **Money stays in integer cents.** `9574389852` is R$ 95,743,898.52 exactly. A float would have
  added the cents of 887,477 rows and arrived somewhere near.

`order_id` and `line_no` are the two columns that are neither. They point at no dimension table:
the order number is kept because somebody will want to find an order's lines, and there is nothing
else to say about an order that the other dimensions do not already say. Lesson 4 gives that a
name.

**The fact table is long and narrow**: 887,477 rows of ten small columns, against dimensions of a
few thousand rows of many wide ones. That difference in shape is the reason lesson 8's columnar
storage works as well as it does.
