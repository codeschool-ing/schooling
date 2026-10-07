-- marts.fact_sales: one row per order line sold, for one day, replaced whole.
-- Run as: psql -v day=2026-03-07 -f load/fact_sales.sql
CREATE TABLE IF NOT EXISTS marts.fact_sales (
  order_date   date    NOT NULL,
  order_id     integer NOT NULL,
  line_no      integer NOT NULL,
  customer_key bigint  NOT NULL,   -- -1: no customer we can name
  book_id      integer NOT NULL,
  quantity     integer NOT NULL,
  line_cents   bigint  NOT NULL);

BEGIN;
DELETE FROM marts.fact_sales WHERE order_date = :'day';
INSERT INTO marts.fact_sales
SELECT o.order_date, o.order_id, l.line_no,
       coalesce(d.customer_key, -1),
       l.book_id, l.quantity, l.line_cents
  FROM staging.orders o
  JOIN staging.order_lines l USING (order_id)
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
 WHERE o.order_date = :'day' AND o.is_sale;
COMMIT;
