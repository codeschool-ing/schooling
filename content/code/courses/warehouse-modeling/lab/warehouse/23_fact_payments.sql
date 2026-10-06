-- Grain: one row per payment. Most orders have one; some have two.
CREATE TABLE fact_payments AS
SELECT d.date_key, s.shop_key, coalesce(c.customer_key, 0) AS customer_key,
       p.order_id, p.payment_id, p.method, p.installments, p.amount_cents
FROM staging.payments p
JOIN staging.orders o USING (order_id)
JOIN dim_date d ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s ON s.shop_id = o.shop_id
LEFT JOIN dim_customer c
       ON c.customer_id = o.customer_id
      AND o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to
ORDER BY p.payment_id;
