-- One row per order line sold. Each run replaces the last thirty days the table
-- already has, and every day after them: the shop changes a sale for weeks after
-- it was made, and a day outside the window is only put right by a full refresh.
{{ config(materialized='incremental',
          incremental_strategy='delete+insert',
          unique_key='order_date') }}
select order_date, order_id, line_no, shop_id, customer_id, book_id, quantity, line_cents
  from {{ ref('int_sales') }}
{% if is_incremental() %}
 where order_date >= (select max(order_date) - 30 from {{ this }})
{% endif %}
