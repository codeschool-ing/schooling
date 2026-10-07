-- marts.dim_customer: a slowly changing dimension of type 2. One row per
-- customer per place they have lived, each valid from one moment to the next.
CREATE TABLE IF NOT EXISTS marts.dim_customer (
  customer_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id  integer     NOT NULL,
  city         text        NOT NULL,
  state        text        NOT NULL,
  valid_from   timestamptz NOT NULL,
  valid_to     timestamptz,                -- NULL while it is still true
  is_current   boolean     NOT NULL);

BEGIN;
-- 1. Close the current version of every customer who moved.
UPDATE marts.dim_customer d
   SET valid_to = s.updated_at, is_current = false
  FROM staging.customers s
 WHERE d.customer_id = s.customer_id AND d.is_current
   AND (d.city, d.state) IS DISTINCT FROM (s.city, s.state);

-- 2. Open a version for every customer who has none current: the new ones,
--    and the ones just closed, from the moment the last version ended.
INSERT INTO marts.dim_customer (customer_id, city, state, valid_from, valid_to, is_current)
SELECT s.customer_id, s.city, s.state,
       coalesce((SELECT max(d.valid_to) FROM marts.dim_customer d
                  WHERE d.customer_id = s.customer_id), s.created_at),
       NULL, true
  FROM staging.customers s
 WHERE NOT EXISTS (SELECT 1 FROM marts.dim_customer d
                    WHERE d.customer_id = s.customer_id AND d.is_current);

-- 3. A customer the shop no longer has asked to be forgotten: every version goes.
DELETE FROM marts.dim_customer d
 WHERE NOT EXISTS (SELECT 1 FROM staging.customers s WHERE s.customer_id = d.customer_id);
COMMIT;
