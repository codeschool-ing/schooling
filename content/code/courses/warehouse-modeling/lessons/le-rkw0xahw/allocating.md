---
title: Allocating to a finer grain
version: 1
---

To put an order-level amount on its lines, give each line a share. The rule here is the one most
shops use for freight: **in proportion to each line's value.** A R$ 68.90 book carries more of the
fee than a R$ 29.90 one.

Proportions produce fractions of a centavo, and money is integer cents. Rounding each share on its
own would make the shares of some orders add up to a centavo more or less than the fee. So the
allocation rounds every share down and then hands the centavos left over, one each, to the lines that
lost the most in the rounding:

```sql
-- Share each order's shipping among its lines, in proportion to their net
-- value, in whole cents; the cents left over go to the largest lines first.
CREATE TABLE fact_sales_shipping AS
WITH shares AS (
    SELECT f.order_id, f.line_no, f.net_cents, o.shipping_cents,
           o.shipping_cents * f.net_cents / sum(f.net_cents) OVER (PARTITION BY f.order_id)
               AS exact_share
    FROM fact_sales f JOIN staging.orders o USING (order_id)
    WHERE o.shipping_cents > 0
),
floored AS (
    SELECT *, CAST(floor(exact_share) AS BIGINT) AS cents,
           shipping_cents - sum(CAST(floor(exact_share) AS BIGINT))
               OVER (PARTITION BY order_id) AS left_over,
           row_number() OVER (PARTITION BY order_id
                              ORDER BY exact_share - floor(exact_share) DESC, line_no) AS place
    FROM shares
)
SELECT order_id, line_no, net_cents,
       cents + CASE WHEN place <= left_over THEN 1 ELSE 0 END AS shipping_cents
FROM floored;

SELECT * FROM fact_sales_shipping WHERE order_id = 112406 ORDER BY line_no;
SELECT sum(shipping_cents) AS allocated FROM fact_sales_shipping;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < allocate.sql
┌──────────┬─────────┬───────────┬────────────────┐
│ order_id │ line_no │ net_cents │ shipping_cents │
│  int64   │  int64  │   int64   │     int64      │
├──────────┼─────────┼───────────┼────────────────┤
│   112406 │       1 │      3290 │            372 │
│   112406 │       2 │      2990 │            338 │
│   112406 │       3 │      6890 │            780 │
└──────────┴─────────┴───────────┴────────────────┘
┌───────────┐
│ allocated │
│  int128   │
├───────────┤
│ 225246280 │
└───────────┘
```

Order 112406 has three books and paid R$ 14.90 of shipping. The R$ 68.90 book carries R$ 7.80, about
half, because it is about half the order. **The three shares add up to 1,490 centavos exactly**, and the
total over every order is 225,246,280: the shipping the shop actually charged, to the centavo.

Two choices in that file are decisions somebody has to own:

- **The basis.** Value is one rule; weight, or an equal share per line, are others. Each gives a
  different answer to "how much freight did Children's books cost us?", and none is wrong. Lesson 12's
  dictionary is where the rule is written next to the column.
- **The rounding.** The centavos left over go to the largest fractional parts first, with the line
  number breaking ties so the result is the same on every run. This is the largest-remainder method;
  giving the spare centavos to the first lines instead is another rule that also adds up, and the two
  move single centavos between lines, never the total.

**Allocate when people need to sum the amount by things only the line knows**: the book, its
department, its publisher. If nobody asks "freight by department", the next section's answer is
simpler.
