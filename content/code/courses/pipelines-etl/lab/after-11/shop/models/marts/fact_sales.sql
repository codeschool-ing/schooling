-- One row per order line sold. Each run replaces the newest day it already
-- has and every day after it, and leaves the older days alone.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) from {{ this }})
{% endif %}
