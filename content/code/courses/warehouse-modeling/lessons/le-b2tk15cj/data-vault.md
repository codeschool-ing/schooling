---
title: A fragment of a Data Vault
version: 1
---

A Data Vault has three kinds of table, and the names say what each holds:

- **Hubs** hold business keys and nothing else: one row per customer number, per ISBN, per order
  number, with the time it was first loaded and the system it came from.
- **Links** hold relationships between hubs: this order belongs to this customer. A link is many-to-many
  by construction, so a relationship that changes later needs no redesign.
- **Satellites** hold descriptive attributes, attached to a hub or a link, with a row for every change,
  stamped with when it was loaded and from where.

Here is a customer hub and a satellite for the tier, built from the shop's data:

```sql
-- A fragment of a Data Vault for customers: a hub of business keys, and a
-- satellite of their tier, one row per change, both stamped with the load.
CREATE TABLE hub_customer AS
SELECT md5(CAST(customer_id AS VARCHAR)) AS customer_hk, customer_id,
       TIMESTAMPTZ '2025-12-31 23:00:00-03' AS load_ts, 'shop.customers' AS record_source
FROM staging.customers;

CREATE TABLE sat_customer_tier AS
SELECT md5(CAST(customer_id AS VARCHAR)) AS customer_hk, valid_from AS load_ts, tier,
       'shop.customer_changes' AS record_source
FROM dim_customer WHERE customer_key > 0;

-- The current tier of every customer, as a reader of the vault has to ask it.
SELECT tier, count(*) AS customers
FROM (SELECT h.customer_id, s.tier
      FROM hub_customer h
      JOIN sat_customer_tier s USING (customer_hk)
      QUALIFY row_number() OVER (PARTITION BY h.customer_hk ORDER BY s.load_ts DESC) = 1)
GROUP BY tier ORDER BY customers DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < vault.sql
┌─────────┬───────────┐
│  tier   │ customers │
│ varchar │   int64   │
├─────────┼───────────┤
│ reader  │     33831 │
│ regular │      4652 │
│ patron  │      1517 │
└─────────┴───────────┘
```

The answer is right: the same 33,831 readers, 4,652 regulars and 1,517 patrons as the current rows of
`dim_customer`. Look at what it took to get, though: a join from hub to satellite and a window function
to pick each customer's latest row. **That is every question asked of a vault**, which is why nobody
reports from one directly. A vault is the layer the stars are built from.

What the vault buys in exchange:

- **Every source change becomes an insert.** A new attribute is a new satellite. A new source is a new
  satellite on an existing hub. Nothing that exists is altered, which makes loads simple and parallel.
- **Auditability.** Every row says which load brought it and from which system, and nothing is ever
  overwritten. "What did the warehouse believe on 3 March, and why?" has an answer.
- **Hash keys.** `md5` of the business key gives the same key in every load and every system without a
  lookup, so hubs, links and satellites can be loaded in any order, in parallel.

Those are real advantages for an organisation with many sources that keep changing. For one source and a
small team, they are three tables where `dim_customer` was one, and a second layer to build before any
report exists.
