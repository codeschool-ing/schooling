-- Grain: one row per customer who came to an author's event. No measure:
-- the row is the fact. The events start at six in the evening.
CREATE TABLE fact_event_attendance AS
SELECT d.date_key, s.shop_key, a.author_key, c.customer_key
FROM staging.event_attendance ea
JOIN staging.events e USING (event_id)
JOIN dim_date d   ON d.date = e.held_on
JOIN dim_shop s   ON s.shop_id = e.shop_id
JOIN dim_author a ON a.author_id = e.author_id
JOIN dim_customer c
  ON c.customer_id = ea.customer_id
 AND e.held_on + INTERVAL 18 HOUR >= c.valid_from
 AND e.held_on + INTERVAL 18 HOUR < c.valid_to
ORDER BY d.date_key, s.shop_key;
