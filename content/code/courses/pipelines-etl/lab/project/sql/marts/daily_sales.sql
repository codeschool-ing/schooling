-- Books and revenue by day, shop and category: one row per combination that
-- sold anything. Built from the line grain and nothing coarser, so that no
-- join can repeat a line.
DROP TABLE IF EXISTS marts.daily_sales;
CREATE TABLE marts.daily_sales AS
SELECT o.order_date,
       o.shop_id,
       b.category,
       sum(l.quantity)::integer    AS books,
       sum(l.line_cents)::bigint   AS revenue_cents
  FROM staging.order_lines l
  JOIN staging.orders o USING (order_id)
  JOIN staging.books  b USING (book_id)
 WHERE o.is_sale
 GROUP BY 1, 2, 3;
