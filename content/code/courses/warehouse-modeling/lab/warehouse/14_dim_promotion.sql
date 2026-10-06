CREATE TABLE dim_promotion AS
SELECT promotion_id AS promotion_key, promotion_id, code, name AS promotion_name,
       percent_off, starts_on, ends_on, coalesce(category, 'All departments') AS applies_to
FROM staging.promotions
UNION ALL
SELECT 0, NULL, '', 'No promotion', 0, NULL, NULL, ''
ORDER BY promotion_key;
