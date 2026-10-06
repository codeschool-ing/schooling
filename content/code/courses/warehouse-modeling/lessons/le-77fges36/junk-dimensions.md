---
title: Small flags, and where to put them
version: 1
---

Some attributes of a fact belong to no dimension. A payment has a method and a number of instalments.
Neither is a thing with a description of its own: `pix` has nothing more to say about it than `pix`.
Three places to put them, and each has a cost:

- **Columns in the fact table.** Simple, and with 586,405 payments it repeats a short string half a
  million times. Lesson 8 shows a columnar store makes that cheap. The cost is elsewhere: the fact
  table becomes a mix of measures and descriptions, and a report tool offers `method` as something to
  sum.
- **One small dimension per flag.** Clean, and it multiplies keys in the fact table: one per flag,
  each pointing at a table of two to six rows.
- **One dimension holding every combination that occurs.** Kimball calls it a **junk dimension**, not
  as a judgement but because it collects the leftovers.

How many combinations actually occur?

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT count(*) AS payments, count(DISTINCT method) AS methods, count(DISTINCT installments) AS installment_counts, count(DISTINCT (method, installments)) AS combinations FROM fact_payments"
┌──────────┬─────────┬────────────────────┬──────────────┐
│ payments │ methods │ installment_counts │ combinations │
│  int64   │  int64  │       int64        │    int64     │
├──────────┼─────────┼────────────────────┼──────────────┤
│   586405 │       4 │                  6 │            9 │
└──────────┴─────────┴────────────────────┴──────────────┘
```

Four methods and six instalment counts could make twenty-four combinations; nine occur, because only
a card is ever split. Nine rows is a dimension:

```sql
-- A junk dimension: every combination of the payment's small flags that
-- actually occurs, once, with a key.
CREATE TABLE dim_payment_profile AS
SELECT row_number() OVER (ORDER BY method, installments) AS payment_profile_key,
       method, installments,
       CASE WHEN installments = 1 THEN 'paid at once' ELSE 'in instalments' END AS terms
FROM (SELECT DISTINCT method, installments FROM fact_payments);

SELECT * FROM dim_payment_profile;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < junk.sql
┌─────────────────────┬───────────┬──────────────┬────────────────┐
│ payment_profile_key │  method   │ installments │     terms      │
│        int64        │  varchar  │    int64     │    varchar     │
├─────────────────────┼───────────┼──────────────┼────────────────┤
│                   1 │ card      │            1 │ paid at once   │
│                   2 │ card      │            2 │ in instalments │
│                   3 │ card      │            3 │ in instalments │
│                   4 │ card      │            4 │ in instalments │
│                   5 │ card      │            5 │ in instalments │
│                   6 │ card      │            6 │ in instalments │
│                   7 │ cash      │            1 │ paid at once   │
│                   8 │ gift_card │            1 │ paid at once   │
│                   9 │ pix       │            1 │ paid at once   │
└─────────────────────┴───────────┴──────────────┴────────────────┘
```

**The fact table gets one key instead of two columns**, and the dimension is where derived labels
like `terms` can live: written once, from the flags, as `region` was written once from the state in
lesson 2.

The rule for what goes in one: **low-cardinality flags and codes that describe the event, that are
used to filter or group, and that have no attributes of their own.** A field with a description of
its own, such as the promotion with its name and dates, is a real dimension. A field with a different
value on almost every row, such as the order number, is not a dimension at all, and lesson 4 deals
with it.
