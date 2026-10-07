-- One row per customer the shop still has: where they live, and since when.
-- No name and no e-mail: the warehouse does not need them (lesson 2).
DROP TABLE IF EXISTS staging.customers CASCADE;
CREATE TABLE staging.customers AS
SELECT customer_id, city, state, created_at, updated_at
  FROM raw.customers;
