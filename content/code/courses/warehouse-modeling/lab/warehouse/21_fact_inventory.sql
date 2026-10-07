-- Grain: one row per shop, per book it stocks, per month-end count.
CREATE TABLE fact_inventory AS
SELECT d.date_key, s.shop_key, b.book_key, sc.on_hand
FROM staging.stock_counts sc
JOIN dim_date d ON d.date = sc.count_date
JOIN dim_shop s ON s.shop_id = sc.shop_id
JOIN dim_book b ON b.book_id = sc.book_id
ORDER BY d.date_key, s.shop_key, b.book_key;
