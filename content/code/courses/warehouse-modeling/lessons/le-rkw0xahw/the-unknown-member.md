---
title: The row for nobody
version: 1
---

Most sales at the physical shops have no customer: somebody pays at the till without a loyalty card.
The operational database records that as an empty `customer_id`. The warehouse could copy the empty
value into `fact_sales`. It points those sales at a row instead:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT * FROM dim_customer WHERE customer_key = 0"
┌──────────────┬─────────────┬─────────────────────────┬─────────┬─────────┬─────────┬──────────────────────────┬──────────────────────────┬────────────┐
│ customer_key │ customer_id │          name           │  tier   │  city   │  state  │        valid_from        │         valid_to         │ is_current │
│    int64     │    int64    │         varchar         │ varchar │ varchar │ varchar │ timestamp with time zone │ timestamp with time zone │  boolean   │
├──────────────┼─────────────┼─────────────────────────┼─────────┼─────────┼─────────┼──────────────────────────┼──────────────────────────┼────────────┤
│            0 │        NULL │ Walk-in, not identified │ none    │ Unknown │ --      │ 1970-01-01 00:00:00-03   │ 9999-12-31 00:00:00-03   │ true       │
└──────────────┴─────────────┴─────────────────────────┴─────────┴─────────┴─────────┴──────────────────────────┴──────────────────────────┴────────────┘
```

Key 0, *Walk-in, not identified*. It is called the **unknown member**, and every dimension that a fact
can lack gets one. To see why, build the alternative, a copy of the sales table with an empty key
where the zero was, and join each to the customer dimension:

```sql
-- What happens if walk-in sales carry no customer at all.
CREATE TABLE sales_null_customer AS
SELECT * REPLACE (CASE WHEN customer_key = 0 THEN NULL ELSE customer_key END AS customer_key)
FROM fact_sales;

SELECT 'with key 0' AS version, count(*) AS lines, sum(net_cents) AS net_cents
FROM fact_sales f JOIN dim_customer c USING (customer_key)
UNION ALL
SELECT 'with NULL', count(*), sum(net_cents)
FROM sales_null_customer f JOIN dim_customer c USING (customer_key);
```

```
ana@lab:~/wh$ duckdb wh.duckdb < null-keys.sql
┌────────────┬────────┬────────────┐
│  version   │ lines  │ net_cents  │
│  varchar   │ int64  │   int128   │
├────────────┼────────┼────────────┤
│ with key 0 │ 887477 │ 9574389852 │
│ with NULL  │ 658707 │ 7095730697 │
└────────────┴────────┴────────────┘
```

**228,770 lines and R$ 24,786,591.55 of sales vanish from the second version.** An inner join keeps only
rows whose key matches, and an empty key matches nothing, not even another empty key. Every report
that joins sales to customers, which is most of them, would quietly leave out a quarter of the shop's
revenue. Nothing errors; the total is simply smaller.

With the unknown member:

- **Every join keeps every row.** Walk-in sales land on key 0 and are counted.
- **The unknown is a value that can be read.** A report grouped by tier shows a line called `none`,
  with a quarter of the revenue in it, which tells the manager something true about the business:
  that many buyers are not in the loyalty programme.
- **"Unknown" and "not applicable" can be told apart.** A dimension can carry more than one special
  row: one for a value that was missing, another for one that does not apply. Lesson 2's *Not yet*
  date is a third kind, for a value that has not happened.

**The rule: a foreign key in a fact table is never empty.** If the value is missing, it points at a
row that says so.
