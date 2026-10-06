---
title: Three marts, three answers
version: 1
---

Finance has never used the warehouse. It built its own mart, from the extract, to answer its own question: how
much money came in. Marketing did the same, a year later, for its campaign reports. Neither is wrong for what it
was built for:

```sql
-- Finance's mart, built by another team straight from the extract:
-- the money customers paid, by the day of the order.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA mart_finance;
CREATE TABLE mart_finance.receipts AS
SELECT CAST(o.ordered_at AS DATE) AS day, o.shop_id,
       sum(p.amount_cents) AS amount_cents
FROM read_csv('extract/payments.csv') p
JOIN read_csv('extract/orders.csv') o USING (order_id)
GROUP BY ALL;
```

```sql
-- Marketing's mart, a third team's: payments by the day they were made.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA mart_marketing;
CREATE TABLE mart_marketing.revenue AS
SELECT CAST(o.paid_at AS DATE) AS day,
       sum(p.amount_cents) AS revenue_cents
FROM read_csv('extract/payments.csv') p
JOIN read_csv('extract/orders.csv') o USING (order_id)
GROUP BY ALL;
```

All three teams are asked the same question in the same meeting: **what was December's revenue?**

```
ana@lab:~/wh$ duckdb wh.duckdb < mart_finance.sql && duckdb wh.duckdb < mart_marketing.sql
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT 'sales' AS mart, sum(net_cents) AS december FROM mart_sales.monthly WHERE year = 2025 AND month = 12
UNION ALL SELECT 'finance', sum(amount_cents) FROM mart_finance.receipts WHERE day BETWEEN '2025-12-01' AND '2025-12-31'
UNION ALL SELECT 'marketing', sum(revenue_cents) FROM mart_marketing.revenue WHERE day BETWEEN '2025-12-01' AND '2025-12-31'"
┌───────────┬───────────┐
│   mart    │ december  │
│  varchar  │  int128   │
├───────────┼───────────┤
│ sales     │ 755814482 │
│ finance   │ 773739182 │
│ marketing │ 365065882 │
└───────────┴───────────┘
```

Three numbers, between R$ 3.65 million and R$ 7.74 million, from three marts that each did what their authors
meant. Nobody made a mistake in the SQL. They made three different decisions about one word:

- **Sales** counts the value of the books sold in orders that were not cancelled, on the day of the order.
- **Finance** counts every payment, which includes the shipping the customer paid, on the day of the order.
- **Marketing** counts every payment on the day it was paid, and only orders that have a payment date.

In the meeting, the conversation that follows is about whose number is right, and it takes the rest of the
hour. **The question that would settle it is which number answers which question**, and that requires knowing
how each was built, which only its authors know. The next section does the work the meeting did not.
