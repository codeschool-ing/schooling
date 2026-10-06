---
title: Building type 2 from a change log
version: 1
---

The warehouse's `dim_customer` was built in one go, from the current customer table and the shop's
log of every change. That is the best source type 2 can have, because the log says exactly when each
change happened:

```sql
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
```

Read it as four steps:

1. **`first_values`**: what each tracked field held when the customer joined. That is the old value
   of the field's first change, or, if it never changed, the value it has today.
2. **`moments`**: one row per moment something tracked changed, with the new value of each field that
   changed then and nothing in the others. A move changes the city and the state at the same instant,
   so it is one moment, not two.
3. **`versions`**: the two lists together, in time order, with each empty field filled by carrying
   the last known value forward (`last_value(... IGNORE NULLS)`), and each version's end taken from
   the start of the next (`lead`).
4. **The final `SELECT`**: a surrogate key for every version, the name as it is spelled now (type 1),
   and the unknown member as key 0.

Two decisions in it deserve a second look:

- **Only tier, city and state make a new version.** The e-mail is not in the warehouse at all: no
  report groups by it, and an address is personal data the warehouse has no use for, which lesson 12
  comes back to. The name is type 1.
- **The last version ends on 31 December 9999**, not on an empty value. A query that asks "which
  version was true at time *t*" can then always use `t >= valid_from AND t < valid_to`, with no special
  case for the current row.

Rebuilding from the whole log is fine for 40,000 customers and two years. A warehouse that has
millions of customers and is loaded every night does not rebuild; it applies one day's changes at a
time to what it already has. The next section does that.
