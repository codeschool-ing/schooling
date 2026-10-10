---
title: Building Lantern's layer
version: 1
---

The layer is one script, `semantic.sql`, and it is the whole of it: a schema called `semantic`,
one small table and five views. Save it in the machine — `nano semantic.sql`, paste, Ctrl+O,
Ctrl+X — and read it once before running it, because every line is a decision from lessons 1 and
2:

```sql
-- semantic.sql: the one place Lantern's definitions are written.
DROP SCHEMA IF EXISTS semantic CASCADE;
CREATE SCHEMA semantic;

CREATE TABLE semantic.state_region (
  state  text PRIMARY KEY,
  region text NOT NULL
);
INSERT INTO semantic.state_region VALUES
  ('SP', 'Southeast'), ('RJ', 'Southeast'), ('MG', 'Southeast'),
  ('PR', 'South'), ('RS', 'South'), ('BA', 'Northeast'), ('AC', 'North');

CREATE VIEW semantic.customers AS
SELECT c.customer_id, c.signed_up, c.state, r.region, c.segment,
       c.channel AS acquisition_channel
FROM shop.customers c
JOIN semantic.state_region r USING (state)
WHERE c.customer_id <> 1;

CREATE VIEW semantic.products AS
SELECT product_id, name AS product, category,
       (price_cents / 100.0)::numeric(10,2) AS list_price
FROM shop.products;

CREATE VIEW semantic.calendar AS
SELECT d::date AS day,
       extract(isodow FROM d)::int AS weekday,
       date_trunc('month', d)::date AS month,
       d < date '2026-06-01' AS month_is_complete
FROM generate_series(date '2025-01-01', date '2026-06-30', interval '1 day') AS d;

CREATE VIEW semantic.order_lines AS
SELECT l.order_id, l.line_no, l.product_id, l.quantity,
       (l.quantity * CASE WHEN l.unit_cents = p.price_cents * 100 THEN p.price_cents
                          ELSE l.unit_cents END / 100.0)::numeric(12,2) AS line_value
FROM shop.order_lines l
JOIN shop.products p USING (product_id)
JOIN shop.orders o USING (order_id)
WHERE o.customer_id <> 1;

CREATE VIEW semantic.orders AS
WITH t AS (SELECT order_id, sum(line_value) AS gross FROM semantic.order_lines GROUP BY order_id)
SELECT o.order_id, o.customer_id,
       (o.ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS order_date,
       o.status, t.gross::numeric(12,2) AS gross,
       (floor(t.gross * o.discount_pct) / 100)::numeric(12,2) AS discount,
       (CASE WHEN o.status = 'paid' THEN t.gross - floor(t.gross * o.discount_pct) / 100
             ELSE 0 END)::numeric(12,2) AS net_revenue
FROM shop.orders o
JOIN t USING (order_id);

COMMENT ON VIEW semantic.orders IS
'One row per order, without the test account. Money in reais.';
COMMENT ON COLUMN semantic.orders.order_date IS
'The day the order was placed, in São Paulo, whatever the session''s time zone.';
COMMENT ON COLUMN semantic.orders.net_revenue IS
'Net revenue: gross minus discount for paid orders, zero for refunded ones. Sum it.';
COMMENT ON VIEW semantic.order_lines IS
'One row per product in an order, without the test account. A line priced at 100 times
the list price, a known fault of an import, is counted at the list price until the
source is fixed.';
```

What each piece carries over:

| piece | the decision it writes down | from |
|---|---|---|
| `state_region` | which region each state belongs to, as rows rather than a `CASE` in somebody's query | lesson 2 |
| `customers` | the test account does not exist; `channel` is renamed `acquisition_channel` | lessons 1 and 2 |
| `order_lines` | a line priced at 100 times its list price is counted at the list price | lesson 1 |
| `orders` | the day is São Paulo's whatever the session says; discounts are rounded down; refunded orders bring no revenue | lesson 2 |
| the comments | what a reader needs to use each view, stored where every tool shows it | lesson 2 |

Money is in reais here rather than cents, as `numeric`, which adds exactly: the layer is for
reading, and `142.90` is what a person expects to see. The correction of the mis-priced lines is
the kind of thing a layer is for and the kind of thing it should say out loud, which is why its
comment does: it is a known fault, corrected in one place, until the load that produced it is
fixed.

Run it:

```
ana@vm:~$ psql -q lantern -f semantic.sql
psql:semantic.sql:2: NOTICE:  schema "semantic" does not exist, skipping
```

The notice is the script dropping a schema that does not exist yet, as `lantern.sql` did the first
time. What was built:

```
lantern=# \dv semantic.*
           List of relations
  Schema  |    Name     | Type | Owner 
----------+-------------+------+-------
 semantic | calendar    | view | ana
 semantic | customers   | view | ana
 semantic | order_lines | view | ana
 semantic | orders      | view | ana
 semantic | products    | view | ana
(5 rows)
```

Five views. `state_region` is a table, so `\dv` does not list it — `\dt semantic.*` does.

**Re-running `lantern.sql` destroys the views.** The views read from the tables in `shop`, and
dropping `shop` with `CASCADE` drops everything that depends on it, including in other schemas. So
after a reset, run `semantic.sql` again too, and then the grants from three sections on.
