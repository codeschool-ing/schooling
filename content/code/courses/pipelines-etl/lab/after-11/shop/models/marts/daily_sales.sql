-- Books and revenue by day, shop and category: one row per combination that sold anything.
select s.order_date,
       s.shop_id,
       b.category,
       sum(s.quantity)::integer  as books,
       sum(s.line_cents)::bigint as revenue_cents
  from {{ ref('int_sales') }} s
  join {{ ref('stg_books') }} b using (book_id)
 group by 1, 2, 3
