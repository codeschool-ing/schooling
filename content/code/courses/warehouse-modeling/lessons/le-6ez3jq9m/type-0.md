---
title: Type 0, the value that never changes
version: 1
---

Some attributes describe a moment rather than a state: the day a customer joined, the shop where
they signed up, the tier they started in. They are true once and stay true. **Type 0 keeps the
original value and ignores every later change.**

```sql
-- Type 0: attributes written once, when the customer joined, and never changed.
CREATE TABLE customer_origin AS
SELECT customer_id,
       CAST(valid_from AS DATE) AS joined_on,
       state                    AS state_when_joined
FROM dim_customer
WHERE customer_key > 0
QUALIFY row_number() OVER (PARTITION BY customer_id ORDER BY valid_from) = 1;

SELECT count(*) AS customers,
       count(*) FILTER (WHERE o.state_when_joined <> c.state) AS live_elsewhere_now
FROM customer_origin o
JOIN staging.customers c USING (customer_id);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < type0.sql
┌───────────┬────────────────────┐
│ customers │ live_elsewhere_now │
│   int64   │       int64        │
├───────────┼────────────────────┤
│     40000 │                622 │
└───────────┴────────────────────┘
```

`state_when_joined` is a type 0 attribute. For 622 of the 40,000 customers it is no longer the state
they live in, and that is the point: "how do customers who joined in São Paulo behave three years
later?" needs the state they joined in, whatever happened since. A column that followed the customer
around would answer a different question.

Type 0 is the right choice far more often than its number suggests:

- Dates of events about the thing: when the customer joined, when a book was published, when a
  shop opened.
- Original classifications kept on purpose for cohort analysis: the first tier, the acquisition
  channel, the campaign that brought somebody in.
- Values that cannot change by definition: a date of birth, the ISBN of an edition.

The danger is calling something type 0 that is merely *rarely* changed. A date of birth is type 0
until somebody discovers it was typed wrongly, and then it needs correcting, which is the next
section.
