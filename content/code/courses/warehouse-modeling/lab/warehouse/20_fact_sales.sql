-- Grain: one row per line of an order that was not cancelled.
CREATE TABLE fact_sales AS
SELECT d.date_key,
       s.shop_key,
       b.book_key,
       coalesce(c.customer_key, 0)                     AS customer_key,
       coalesce(l.promotion_id, 0)                     AS promotion_key,
       o.order_id,
       l.line_no,
       l.quantity,
       l.quantity * l.unit_price_cents                 AS gross_cents,
       l.discount_cents,
       l.quantity * l.unit_price_cents - l.discount_cents AS net_cents
FROM staging.order_lines l
JOIN staging.orders o USING (order_id)
JOIN dim_date d       ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s       ON s.shop_id = o.shop_id
JOIN dim_book b       ON b.book_id = l.book_id
LEFT JOIN dim_customer c
       ON c.customer_id = o.customer_id
      AND o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to
WHERE o.status <> 'cancelled'
ORDER BY o.order_id, l.line_no;
