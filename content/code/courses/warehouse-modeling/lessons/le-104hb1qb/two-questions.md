---
title: Two questions asked of one database
version: 1
---

Ana's database answers two kinds of question all day, and they look alike because both are SQL.

The first comes from a till. A customer at Paulista buys two books and pays by Pix, and the till
writes it down:

```sql
-- One sale at the Paulista till: two books, paid by Pix.
BEGIN;
INSERT INTO orders (order_id, shop_id, customer_id, ordered_at, status)
VALUES (900001, 1, 31579, '2026-01-02 10:14:00-03', 'completed');
INSERT INTO order_lines (order_id, line_no, book_id, quantity, unit_price_cents)
VALUES (900001, 1, 2395, 1, 15990),
       (900001, 2, 1036, 1, 12590);
INSERT INTO payments (payment_id, order_id, method, installments, amount_cents)
VALUES (2000001, 900001, 'pix', 1, 28580);
COMMIT;
```

```
ana@lab:~/wh$ psql -f sale.sql
BEGIN
INSERT 0 1
INSERT 0 2
INSERT 0 1
COMMIT
```

Four rows in three tables, in one transaction, and the database is done. **The till asks "record
this"**, and a moment later it asks "show me that order", by its number. Every question it asks
names one order, one customer, one book.

The second comes from the manager, once a month. **"How much did each department sell, this year
against last?"** It names no order. It needs every line the shop has ever written, joined to the
book it sold, the category the book sits in and the department above that:

```sql
-- Revenue by year and department, from the shop's own database.
SELECT extract(year FROM o.ordered_at) AS year,
       coalesce(top.name, mid.name)    AS department,
       round(sum(l.quantity * l.unit_price_cents - l.discount_cents) / 100.0, 2)
                                       AS revenue_brl
FROM orders o
JOIN order_lines l          USING (order_id)
JOIN books b                USING (book_id)
JOIN categories leaf        ON leaf.category_id = b.category_id
JOIN categories mid         ON mid.category_id = leaf.parent_id
LEFT JOIN categories top    ON top.category_id = mid.parent_id
WHERE o.status <> 'cancelled' AND o.ordered_at < '2026-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;
```

```
ana@lab:~/wh$ psql -c "\timing on" -f report.sql
Timing is on.
 year | department  | revenue_brl 
------+-------------+-------------
 2024 | Children    |  2987810.70
 2024 | Comics      |  2553516.52
 2024 | Fiction     | 18389500.17
 2024 | Non-fiction | 17796358.42
 2025 | Children    |  4046265.63
 2025 | Comics      |  3018557.77
 2025 | Fiction     | 22994642.78
 2025 | Non-fiction | 23957246.53
(8 rows)

Time: 1607.639 ms (00:01.608)
```

Eight rows of answer. To produce them, PostgreSQL read all 895,334 order lines and every order they
belong to, and it took 1.6 seconds on an idle machine with nothing else asking.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two questions against the same tables. On the left, the till: one order and its two lines, found through two indexes, eleven pages read in 0.192 milliseconds. On the right, the report: every row of orders and order lines read, 12,518 pages from memory and 14,571 more written to temporary files and read back, in 1.6 seconds, to produce eight rows.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">the till: record this, show me that</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">the report: summarise everything</text><rect x=\"40\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"48\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"48\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"200\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">order_lines</text><rect x=\"208\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"208\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"180\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3 rows found by key</text><text x=\"180\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">11 pages · 0.192 ms</text><rect x=\"400\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders</text><rect x=\"408\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"408\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"560\" y=\"50\" width=\"120\" height=\"190\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">order_lines</text><rect x=\"568\" y=\"80\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"91\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"102\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"113\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"124\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"135\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"146\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"157\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"168\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"179\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"190\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"201\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"212\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"568\" y=\"223\" width=\"104\" height=\"7\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"540\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">every row read, 8 rows out</text><text x=\"540\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">12,518 pages + temp files · 1.6 s</text><line x1=\"360\" y1=\"50\" x2=\"360\" y2=\"280\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line></svg>", "caption": "The till's question and the report's, against the same two tables. The highlighted rows are the ones each one had to read."}
```

**The two questions differ in shape, not in difficulty.** The till touches a handful of rows and
needs them now; the report touches every row and can wait a little. One writes, the other only
reads. One cares about today, the other compares this year with last. The next two sections take
each shape apart, because the whole design of a warehouse follows from the difference.
