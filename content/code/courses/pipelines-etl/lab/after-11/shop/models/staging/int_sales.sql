-- Every order line that was a sale, with its order's date, shop and customer.
-- Ephemeral: never built, only pasted into the models that use it.
{{ config(materialized='ephemeral') }}
select o.order_date, o.order_id, l.line_no, o.shop_id, o.customer_id,
       l.book_id, l.quantity, l.line_cents
  from {{ ref('stg_order_lines') }} l
  join {{ ref('stg_orders') }} o using (order_id)
 where o.is_sale
