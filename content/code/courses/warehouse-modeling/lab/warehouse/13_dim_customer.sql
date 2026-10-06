-- Slowly changing, type 2 on tier, city and state: a new row every time one
-- of them changed, each row valid from the change until the next one.
-- The name is type 1: every version carries the name as it is spelled now.
CREATE TABLE dim_customer AS
WITH tracked AS (
    SELECT * FROM staging.customer_changes WHERE field IN ('tier', 'city', 'state')
),
-- what each tracked field held when the customer joined: the old value of its
-- first change, or the current value if it never changed
first_values AS (
    SELECT c.customer_id, c.created_at AS valid_from,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'tier' ORDER BY changed_at LIMIT 1), c.tier)  AS tier,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'city' ORDER BY changed_at LIMIT 1), c.city)  AS city,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'state' ORDER BY changed_at LIMIT 1), c.state) AS state
    FROM staging.customers c
),
-- one event per moment something tracked changed
moments AS (
    SELECT customer_id, changed_at AS valid_from,
           max(new_value) FILTER (WHERE field = 'tier')  AS tier,
           max(new_value) FILTER (WHERE field = 'city')  AS city,
           max(new_value) FILTER (WHERE field = 'state') AS state
    FROM tracked GROUP BY customer_id, changed_at
),
timeline AS (
    SELECT * FROM first_values
    UNION ALL
    SELECT * FROM moments
),
-- carry each field forward until the moment that changes it
versions AS (
    SELECT customer_id, valid_from,
           last_value(tier IGNORE NULLS)  OVER w AS tier,
           last_value(city IGNORE NULLS)  OVER w AS city,
           last_value(state IGNORE NULLS) OVER w AS state,
           lead(valid_from) OVER (PARTITION BY customer_id ORDER BY valid_from) AS next_from
    FROM timeline
    WINDOW w AS (PARTITION BY customer_id ORDER BY valid_from
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT row_number() OVER (ORDER BY v.customer_id, v.valid_from) AS customer_key,
       v.customer_id,
       c.name,
       v.tier,
       v.city,
       v.state,
       v.valid_from,
       coalesce(v.next_from, TIMESTAMPTZ '9999-12-31 00:00:00-03') AS valid_to,
       v.next_from IS NULL                                     AS is_current
FROM versions v JOIN staging.customers c USING (customer_id)
UNION ALL
SELECT 0, NULL, 'Walk-in, not identified', 'none', 'Unknown', '--',
       TIMESTAMPTZ '1970-01-01 00:00:00-03', TIMESTAMPTZ '9999-12-31 00:00:00-03', true
ORDER BY customer_key;
