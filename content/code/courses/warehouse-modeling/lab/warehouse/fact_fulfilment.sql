-- Grain: one row per online order, updated as it moves. A milestone not
-- reached yet points at the 'Not yet' date, key 0.
CREATE TABLE fact_fulfilment AS
SELECT o.order_id,
       c.customer_key,
       CAST(strftime(o.ordered_at, '%Y%m%d') AS INTEGER)                  AS ordered_date_key,
       coalesce(CAST(strftime(o.paid_at, '%Y%m%d') AS INTEGER), 0)        AS paid_date_key,
       coalesce(CAST(strftime(o.shipped_at, '%Y%m%d') AS INTEGER), 0)     AS shipped_date_key,
       coalesce(CAST(strftime(o.delivered_at, '%Y%m%d') AS INTEGER), 0)   AS delivered_date_key,
       o.status,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.shipped_at AS DATE))   AS days_to_ship,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.delivered_at AS DATE)) AS days_to_deliver
FROM staging.orders o
JOIN staging.shops sh USING (shop_id)
JOIN dim_customer c
  ON c.customer_id = o.customer_id
 AND o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to
WHERE sh.channel = 'online' AND o.status <> 'cancelled'
ORDER BY o.order_id;
