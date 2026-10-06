---
title: Asking a type 2 dimension a question
version: 1
---

The point of type 2 is that a fact can be described **as it was** or **as it is now**, and the two
are different questions. Revenue of 2025 by loyalty tier, both ways:

```sql
-- Revenue of 2025 by loyalty tier: the tier the customer had when they
-- bought, against the tier they have now.
SELECT d.tier AS tier_at_sale, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer d USING (customer_key)
JOIN dim_date dt    USING (date_key)
WHERE dt.year = 2025 AND d.customer_key > 0
GROUP BY ALL ORDER BY revenue_brl DESC;

SELECT now.tier AS tier_today, round(sum(f.net_cents) / 100, 2) AS revenue_brl
FROM fact_sales f
JOIN dim_customer d   USING (customer_key)
JOIN dim_customer now ON now.customer_id = d.customer_id AND now.is_current
JOIN dim_date dt      USING (date_key)
WHERE dt.year = 2025 AND d.customer_key > 0
GROUP BY ALL ORDER BY revenue_brl DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < by-tier.sql
┌──────────────┬─────────────┐
│ tier_at_sale │ revenue_brl │
│   varchar    │   double    │
├──────────────┼─────────────┤
│ reader       │ 35689643.01 │
│ regular      │  3720786.22 │
│ patron       │   897527.15 │
└──────────────┴─────────────┘
┌────────────┬─────────────┐
│ tier_today │ revenue_brl │
│  varchar   │   double    │
├────────────┼─────────────┤
│ reader     │ 34440811.35 │
│ regular    │  4657279.06 │
│ patron     │  1209865.97 │
└────────────┴─────────────┘
```

The first result groups each sale by the version it points at: the tier the customer **had when they
bought**. The second goes from that version to the customer's current one and groups by the tier they
**have today**.

**Readers bought R$ 35,689,643.01 in 2025, as readers. Customers who are readers today bought
R$ 34,440,811.35.** The difference, R$ 1,248,831.66, is what was bought as a reader by people who have
since been promoted. Both numbers are correct:

- **Tier at the time** answers "how much does the programme's lowest tier buy?" — what the manager
  needs to know before changing what readers are offered.
- **Tier today** answers "how much did our current patrons spend this year?" — what the manager needs
  to know before deciding whom to send an invitation.

A report that does not say which one it shows will be read as the other one by somebody.

The first query is the ordinary star join: the fact table already carries the right version's key,
because the load looked it up when the sale arrived (`20_fact_sales.sql` joins on
`o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to`). **The time travel is done once, at
load time**, and every query after that gets "as it was" for free. "As it is now" costs one more join
on `customer_id` and `is_current`, and section 10 shows a way to store that too.
