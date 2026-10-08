---
title: Loading one month at a time
version: 2
---

Most sources keep no change log. What the warehouse gets instead is a **snapshot**: the whole customer
table, as it is at the moment of the extract. Lesson 1's generator wrote three of them into `extracts/`,
taken at midnight on the first of October, November and December 2025. Type 2 from snapshots works by comparison: what does the
extract say, against what the dimension's current rows say?

This dimension is built beside the warehouse's own, as `dim_customer_m`. The first load is everybody,
one version each:

```sql
-- A type 2 customer dimension loaded from monthly extracts. The first month:
-- one current version of everybody, from the day of the extract.
CREATE SEQUENCE customer_key_seq START 1;
CREATE TABLE dim_customer_m (
    customer_key BIGINT PRIMARY KEY,
    customer_id  BIGINT NOT NULL,
    name         VARCHAR,
    tier         VARCHAR,
    city         VARCHAR,
    state        VARCHAR,
    valid_from   DATE NOT NULL,
    valid_to     DATE NOT NULL,
    is_current   BOOLEAN NOT NULL
);
INSERT INTO dim_customer_m
SELECT nextval('customer_key_seq'), customer_id, name, tier, city, state,
       DATE '2025-10-01', DATE '9999-12-31', true
FROM read_csv('extracts/customers_2025-10-01.csv');
```

Every later month runs the same script, with the month's date in a variable:

```sql
-- Load one month's extract into the type 2 dimension. Run with the extract's
-- date in the variable load_date.
BEGIN;
CREATE OR REPLACE TEMP TABLE ext AS
SELECT * FROM read_csv('extracts/customers_' || getvariable('load_date') || '.csv');

-- 1. Type 1: a corrected name is written into every version of the customer.
UPDATE dim_customer_m d SET name = e.name
FROM ext e
WHERE d.customer_id = e.customer_id AND d.name <> e.name;

-- 2. Close the current version of everybody whose tracked attributes changed.
UPDATE dim_customer_m d SET valid_to = getvariable('load_date'), is_current = false
FROM ext e
WHERE d.customer_id = e.customer_id AND d.is_current
  AND (d.tier, d.city, d.state) IS DISTINCT FROM (e.tier, e.city, e.state);

-- 3. Open a version for everybody who now has no current row: the ones just
--    closed, and customers who joined during the month.
INSERT INTO dim_customer_m
SELECT nextval('customer_key_seq'), e.customer_id, e.name, e.tier, e.city, e.state,
       getvariable('load_date'), DATE '9999-12-31', true
FROM ext e
WHERE NOT EXISTS (SELECT 1 FROM dim_customer_m d
                  WHERE d.customer_id = e.customer_id AND d.is_current);
COMMIT;

SELECT count(*) AS rows, count(*) FILTER (WHERE is_current) AS current,
       count(*) FILTER (WHERE valid_to = getvariable('load_date')) AS closed_now,
       count(*) FILTER (WHERE valid_from = getvariable('load_date')) AS opened_now
FROM dim_customer_m;
```

Three steps, each one set-based, inside one transaction:

1. **The type 1 column first.** A corrected name is written into every version of the customer, old
   versions included, because it was never spelled the other way.
2. **Close what changed.** Every current row whose tier, city or state differs from the extract gets
   its `valid_to` set to the extract's date and stops being current. `IS DISTINCT FROM` treats two empty
   values as equal, which plain `<>` does not.
3. **Open what is missing.** Every customer in the extract with no current row gets one: the customers
   closed in step 2, and the customers who joined during the month. One `INSERT` serves both.

```
ana@lab:~/wh$ duckdb wh.duckdb < first_load.sql
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE load_date = DATE '2025-11-01'" < load_month.sql
┌───────┬─────────┬────────────┬────────────┐
│ rows  │ current │ closed_now │ opened_now │
│ int64 │  int64  │   int64    │   int64    │
├───────┼─────────┼────────────┼────────────┤
│ 39328 │   39065 │        263 │       1214 │
└───────┴─────────┴────────────┴────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE load_date = DATE '2025-12-01'" < load_month.sql
┌───────┬─────────┬────────────┬────────────┐
│ rows  │ current │ closed_now │ opened_now │
│ int64 │  int64  │   int64    │   int64    │
├───────┼─────────┼────────────┼────────────┤
│ 40532 │   40000 │        269 │       1204 │
└───────┴─────────┴────────────┴────────────┘
```

November closed 263 versions and opened 1,214: the 263 new versions of people who changed, and 951
customers who joined during October. December closed 269 and opened 1,204, and ended with 40,000
current rows, one per customer, as it should.

## Run it twice

A load that fails halfway gets run again. Here is December, run a second time:

```
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE load_date = DATE '2025-12-01'" < load_month.sql
┌───────┬─────────┬────────────┬────────────┐
│ rows  │ current │ closed_now │ opened_now │
│ int64 │  int64  │   int64    │   int64    │
├───────┼─────────┼────────────┼────────────┤
│ 40532 │   40000 │        269 │       1204 │
└───────┴─────────┴────────────┴────────────┘
```

**Nothing changed.** After the first run every current row already matches the extract, so step 2
finds nothing to close and step 3 nothing to open. A load that can be repeated without harm is called
**idempotent**, and it is the property that lets somebody rerun last night's job at nine in the morning
without first working out how far it got. `pipelines-etl` makes this a rule for every load.
