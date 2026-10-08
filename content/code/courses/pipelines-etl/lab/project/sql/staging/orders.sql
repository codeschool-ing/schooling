-- One row per order, as the shop has it, with the shop's own date worked out once.
DROP TABLE IF EXISTS staging.orders CASCADE;
CREATE TABLE staging.orders AS
SELECT order_id,
       shop_id,
       customer_id,
       ordered_at,
       (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS order_date,
       status,
       status = 'completed' AS is_sale
  FROM raw.orders;
