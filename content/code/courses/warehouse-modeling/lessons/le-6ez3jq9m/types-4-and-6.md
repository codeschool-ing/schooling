---
title: Types 4 and 6, the combinations
version: 1
---

The numbering goes past 3, and two of the later types are worth knowing because they solve problems
type 2 leaves.

## Type 6: the current value on every version

Section 06 needed an extra join to group sales by the tier customers have *today*. Type 6 stores that
answer: every version of a customer carries its own value **and** the customer's current value, in a
second column. The name is the arithmetic of the three it combines, 1 + 2 + 3: type 2 rows, with a
type 1 column of the current value, which is also a type 3 idea of keeping two values side by side.

```sql
-- Type 6: type 2 rows, each also carrying the customer's current tier.
CREATE TABLE dim_customer_t6 AS
SELECT d.*, now.tier AS current_tier
FROM dim_customer d
LEFT JOIN dim_customer now ON now.customer_id = d.customer_id AND now.is_current;

SELECT d.tier AS tier_at_sale, d.current_tier, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer_t6 d USING (customer_key)
JOIN dim_date dt       USING (date_key)
WHERE dt.year = 2025 AND d.tier = 'reader'
GROUP BY ALL ORDER BY revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < type6.sql
┌──────────────┬──────────────┬─────────────┐
│ tier_at_sale │ current_tier │ revenue_brl │
│   varchar    │   varchar    │   double    │
├──────────────┼──────────────┼─────────────┤
│ reader       │ reader       │ 34440811.35 │
│ reader       │ regular      │  1208862.02 │
│ reader       │ patron       │    39969.64 │
└──────────────┴──────────────┴─────────────┘
```

One query now answers both questions at once. Of the R$ 35.7 million bought by readers in 2025, R$ 34.4
million came from people who are still readers, R$ 1.2 million from people who have since become
regulars, and R$ 39,969.64 from people who went on to become patrons. **That last row is the
programme working**, and neither of section 06's two tables could show it.

The cost is the load: when a customer's tier changes, the `current_tier` of **every** earlier version
has to be updated too, which is a type 1 overwrite across their whole history.

## Type 4: a mini-dimension for what changes fast

Type 2 grows by one row per change. For an attribute that changes often in a large dimension, such
as a credit score updated monthly on millions of customers, that is too many rows. Type 4 moves the
fast-changing attributes out into a small table of their own, a **mini-dimension**, with one row per
combination of values that occurs (bands rather than exact numbers), and puts a second key in the fact
table pointing at it. The customer dimension stays slow; the mini-dimension's key on each fact row
records what the fast attributes were at that moment.

It is lesson 3's junk dimension again, used for a different reason. The shop does not need one: its
tiers change a few thousand times in two years, and type 2 absorbs that easily.
