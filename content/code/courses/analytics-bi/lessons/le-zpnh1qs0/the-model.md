---
title: The model: what the CRM should know
version: 1
---

A sync sends rows, so the first thing to write is the query whose rows are what the CRM should
contain. Reverse ETL tools call it the **model**. For Lantern it is one row per customer, with a
handful of fields a salesperson can act on, computed from the semantic layer of lesson 3 so that
net revenue here means what it means everywhere else.

The model lives in a schema of its own, `activation`, beside two tables that are the sync's memory.
Make a directory for this lesson, `mkdir ~/reverse && cd ~/reverse`, and save this as
`activation.sql` in it:

```sql
-- activation.sql: what the CRM should know about each customer, and the sync's memory.
DROP SCHEMA IF EXISTS activation CASCADE;
CREATE SCHEMA activation;

CREATE VIEW activation.crm_contacts AS
WITH asof AS (SELECT max(order_date) AS day FROM semantic.orders)
SELECT 'lantern-' || c.customer_id AS external_id,
       c.segment, c.region,
       count(o.order_id) AS orders,
       coalesce(sum(o.net_revenue), 0) AS net_revenue,
       max(o.order_date) AS last_order,
       CASE WHEN max(o.order_date) >= asof.day - 45 THEN 'active'
            WHEN max(o.order_date) >= asof.day - 120 THEN 'at risk'
            ELSE 'lapsed' END AS health
FROM semantic.customers c
CROSS JOIN asof
LEFT JOIN semantic.orders o USING (customer_id)
GROUP BY c.customer_id, c.segment, c.region, asof.day;

CREATE TABLE activation.last_sent (
  external_id text PRIMARY KEY,
  payload     jsonb NOT NULL,
  sent_at     timestamptz NOT NULL
);

CREATE TABLE activation.sync_log (
  run_id      int NOT NULL,
  external_id text NOT NULL,
  action      text NOT NULL,
  http_status int NOT NULL,
  at          timestamptz NOT NULL DEFAULT now()
);
```

Three decisions are written into the view:

- **The key is `external_id`**, the shop's own customer id with a prefix. It is the identity the CRM
  will use to recognise the same customer next time, and the next sections show why it has to be the
  shop's id and not the CRM's.
- **`health` is a definition**, like everything in lesson 2. A customer is *active* if they ordered in
  the last 45 days, *at risk* up to 120, *lapsed* beyond. Forty-five days is where three gaps in four
  between a customer's orders end, from lesson 2's measurement; the day it is measured from is the
  last day in the data, as lesson 6 insisted, not today's date.
- **The fields are few**: segment, region, order count, lifetime net revenue, last order, health.

`last_sent` will hold, per contact, exactly what was last sent and accepted; `sync_log` will hold every
attempt. Load it:

```
ana@vm:~/reverse$ psql -q lantern -f activation.sql
psql:activation.sql:2: NOTICE:  schema "activation" does not exist, skipping
```

Three customers, and how the 2,649 split by health:

```
lantern=# SELECT * FROM activation.crm_contacts
lantern-# WHERE external_id IN ('lantern-2', 'lantern-10', 'lantern-1500');
 external_id  | segment |  region   | orders | net_revenue | last_order | health  
--------------+---------+-----------+--------+-------------+------------+---------
 lantern-2    | home    | Southeast |      2 |      329.60 | 2026-03-05 | at risk
 lantern-10   | home    | South     |      1 |       41.31 | 2025-06-11 | lapsed
 lantern-1500 | home    | Southeast |      6 |      553.22 | 2026-01-18 | lapsed
(3 rows)

lantern=# SELECT health, count(*) FROM activation.crm_contacts GROUP BY health ORDER BY 2 DESC;
 health  | count 
---------+-------
 lapsed  |  1073
 active  |   967
 at risk |   609
(3 rows)
```

Customer 1500 is worth a second look: six orders, R$ 553.22 over the shop's life, and *lapsed* — no
order since January. That is the customer somebody would want to call, and the reason the field is
worth sending.
