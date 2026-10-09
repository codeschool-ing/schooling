-- One row per order, as the shop has it, with the shop's own date worked out once.
select order_id,
       shop_id,
       customer_id,
       ordered_at,
       (ordered_at at time zone 'America/Sao_Paulo')::date as order_date,
       status,
       status = 'completed' as is_sale
  from {{ source('raw', 'orders') }}
