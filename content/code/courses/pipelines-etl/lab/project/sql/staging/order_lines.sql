-- One row per order line, with what the line was worth.
DROP TABLE IF EXISTS staging.order_lines CASCADE;
CREATE TABLE staging.order_lines AS
SELECT order_id,
       line_no,
       book_id,
       quantity,
       unit_price_cents,
       quantity * unit_price_cents AS line_cents
  FROM raw.order_lines;
