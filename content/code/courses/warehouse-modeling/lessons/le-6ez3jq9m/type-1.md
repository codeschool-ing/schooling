---
title: Type 1, overwrite
version: 1
---

**Type 1 overwrites the old value with the new one.** The dimension has one row per customer, the
row says whatever the source says today, and nothing records what it said before. It is what the
operational database does, and what a warehouse does by default if nobody decides otherwise.

Build a type 1 customer dimension from an extract, and ask it how much the shop sold in 2024 to
customers in Minas Gerais and Paraná:

```sql
-- Type 1: one row per customer, overwritten with whatever the extract says.
CREATE OR REPLACE TABLE dim_customer_t1 AS
SELECT customer_id, name, tier, city, state
FROM read_csv('extracts/customers_' || getvariable('extract_date') || '.csv');

SELECT c.state, round(sum(f.net_cents) / 100, 2) AS sold_in_2024_brl
FROM fact_sales f
JOIN dim_customer d     ON d.customer_key = f.customer_key
JOIN dim_customer_t1 c  ON c.customer_id = d.customer_id
JOIN dim_date dt        ON dt.date_key = f.date_key
WHERE dt.year = 2024 AND c.state IN ('MG', 'PR')
GROUP BY ALL ORDER BY c.state;
```

```
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE extract_date = DATE '2025-10-01'" < type1.sql
┌─────────┬──────────────────┐
│  state  │ sold_in_2024_brl │
│ varchar │      double      │
├─────────┼──────────────────┤
│ MG      │       4688508.55 │
│ PR      │       3575257.82 │
└─────────┴──────────────────┘
ana@lab:~/wh$ duckdb wh.duckdb -cmd "SET VARIABLE extract_date = DATE '2025-12-01'" < type1.sql
┌─────────┬──────────────────┐
│  state  │ sold_in_2024_brl │
│ varchar │      double      │
├─────────┼──────────────────┤
│ MG      │       4679116.31 │
│ PR      │       3573642.13 │
└─────────┴──────────────────┘
```

**The same question about 2024, asked in October 2025 and again in December 2025, gives two
different answers.** Minas Gerais lost R$ 9,392.24 of 2024 sales between the two loads. Nothing about
2024 changed in those two months. More customers moved out of Minas Gerais than into it in October and
November, the overwrite took their whole history with them, and a report that was printed in October no longer
matches the warehouse.

That is the defining property of type 1: **the past is rewritten to look like the present.** It is
wrong for anything people analyse over time, and exactly right for one kind of change:

- **Corrections.** A name typed wrongly at the till, a city spelled two ways, a date of birth
  entered with the day and month swapped. The old value was never true, so there is no history worth
  keeping, and every past sale should show the corrected value.
- **Attributes nobody analyses.** A customer's preferred language for e-mails, a book's cover image.
  If no report groups by it over time, keeping its history costs space and buys nothing.

The shop's customer names are type 1 for the first reason: the change log has 508 name changes, and
every one is a correction of how the name was typed at the till.
