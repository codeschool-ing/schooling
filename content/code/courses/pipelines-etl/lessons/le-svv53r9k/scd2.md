---
title: The slowly changing dimension, loaded
version: 1
---

`warehouse-modeling` designed the customer dimension as **type 2**: when a customer moves, the old
row is not overwritten but closed, and a new row is opened, so a sale made while they lived in São
Paulo stays a São Paulo sale after they move. That lesson drew it. This one has to load it, every
night, from a shop that only ever knows where somebody lives *now*.

It reads `staging.customers`, which lesson 6 never needed. One more file in `sql/staging`,
`customers.sql`, builds it, and `run_sql.sh` picks it up with the others:

```sql
-- One row per customer the shop still has: where they live, and since when.
-- No name and no e-mail: the warehouse does not need them (lesson 2).
DROP TABLE IF EXISTS staging.customers CASCADE;
CREATE TABLE staging.customers AS
SELECT customer_id, city, state, created_at, updated_at
  FROM raw.customers;
```

The load is three statements in one transaction:

```
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
```

1. **Close** the current version of every customer whose city or state no longer matches the shop.
   `IS DISTINCT FROM` rather than `<>`, so a change to or from `NULL` counts as a change.
2. **Open** a version for every customer who has no current one — new customers, and the ones the
   first statement just closed. The new version starts where the last one ended, so there is no gap
   and no overlap between them.
3. **Erase** every version of a customer the shop no longer has. The next section is about why
   that one is not optional.

Ana plays the days from 4 to 15 March with `shop day`, running `nightly.sh` after each. On the 15th, customer
3145 moves from São Paulo to Rio de Janeiro:

```
ana@vm:~/etl$ psql -d wh -c "SELECT customer_key, customer_id, city, state, valid_from, valid_to, is_current FROM marts.dim_customer WHERE customer_id = 3145 ORDER BY valid_from"
 customer_key | customer_id |      city      | state |       valid_from       |        valid_to        | is_current 
--------------+-------------+----------------+-------+------------------------+------------------------+------------
         3133 |        3145 | São Paulo      | SP    | 2025-05-01 12:00:00-03 | 2026-03-15 08:16:38-03 | f
         5393 |        3145 | Rio de Janeiro | RJ    | 2026-03-15 08:16:38-03 |                        | t
(2 rows)

ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS versions, count(DISTINCT customer_id) AS customers, count(*) FILTER (WHERE NOT is_current) AS closed FROM marts.dim_customer"
 versions | customers | closed 
----------+-----------+--------
     5413 |      5366 |     47
(1 row)
```

Two rows for one customer: São Paulo until 08:16:38 on 15 March, Rio de Janeiro from that moment
on, with the end of one and the start of the next equal to the second. Across the whole dimension,
47 versions have been closed in fifteen days.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l07-scd2\" aria-label=\"Customer 3145 on a time line. Version 3133, São Paulo, is valid from 1 May 2025 to 08:16:38 on 15 March 2026. Version 5393, Rio de Janeiro, is valid from that moment with no end. A sale on 11 March points to version 3133, because the sale happened while that version was true.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M40.0 160.0 L690.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"110.0\" width=\"430.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">key 3133 · São Paulo</text><rect x=\"470.0\" y=\"110.0\" width=\"210.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"575.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">key 5393 · Rio de Janeiro</text><text x=\"678.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">still true</text><path d=\"M470.0 80.0 L470.0 166.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"470.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">moved 15 March 08:16:38</text><circle cx=\"400.0\" cy=\"160.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sale, 11 March</text><path d=\"M400.0 154.0 L400.0 142.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"40.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 May 2025</text></svg>", "caption": "The end of one version is the start of the next. A fact is joined to the version whose interval holds the moment of the sale."}
```

## What the dimension cannot know

**It knows only what it saw.** The load reads the shop once a night, so a customer who moves twice
in one day appears to have moved once, to the second address — the first one was never seen. Lesson
5's change data capture is the cure: every update arrives, and each can close a version.

**And it starts the day it starts.** On the first night every customer got a version valid from
the day they signed up, because the shop's current city is all there was to go on. A customer who
moved in January is recorded as having always lived where they lived on 1 March. That is a
decision, and the comment on the table should say so; a dimension built later from a full history
of changes would know better.
