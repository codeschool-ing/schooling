---
title: When the sync fails, and how you find out
version: 1
---

A sync fails in a way a dashboard never does: partly. Most rows arrive, some do not, and the CRM shows
whatever the last successful request left. **The failure is invisible from the CRM**, so the sync has to
make it visible itself.

The most common cause is not the network. It is the model and the destination disagreeing about what a
field may hold. Marketing asks for a new health value, *new*, for customers whose first order is less
than thirty days old, and the view is changed:

```sql
CREATE OR REPLACE VIEW activation.crm_contacts AS
WITH asof AS (SELECT max(order_date) AS day FROM semantic.orders)
SELECT 'lantern-' || c.customer_id AS external_id,
       c.segment, c.region,
       count(o.order_id) AS orders,
       coalesce(sum(o.net_revenue), 0) AS net_revenue,
       max(o.order_date) AS last_order,
       CASE WHEN min(o.order_date) >= asof.day - 30 THEN 'new'
            WHEN max(o.order_date) >= asof.day - 45 THEN 'active'
            WHEN max(o.order_date) >= asof.day - 120 THEN 'at risk'
            ELSE 'lapsed' END AS health
FROM semantic.customers c
CROSS JOIN asof
LEFT JOIN semantic.orders o USING (customer_id)
GROUP BY c.customer_id, c.segment, c.region, asof.day;
```

Nobody changed the CRM, whose picklist still has three values. The view, then the next sync, showing
its last four lines:

```
lantern=# CREATE OR REPLACE VIEW activation.crm_contacts AS
lantern-# WITH asof AS (SELECT max(order_date) AS day FROM semantic.orders)
lantern-# SELECT 'lantern-' || c.customer_id AS external_id,
lantern-#        c.segment, c.region,
lantern-#        count(o.order_id) AS orders,
lantern-#        coalesce(sum(o.net_revenue), 0) AS net_revenue,
lantern-#        max(o.order_date) AS last_order,
lantern-#        CASE WHEN min(o.order_date) >= asof.day - 30 THEN 'new'
lantern-#             WHEN max(o.order_date) >= asof.day - 45 THEN 'active'
lantern-#             WHEN max(o.order_date) >= asof.day - 120 THEN 'at risk'
lantern-#             ELSE 'lapsed' END AS health
lantern-# FROM semantic.customers c
lantern-# CROSS JOIN asof
lantern-# LEFT JOIN semantic.orders o USING (customer_id)
lantern-# GROUP BY c.customer_id, c.segment, c.region, asof.day;
CREATE VIEW
ana@vm:~/reverse$ bash sync.sh 2>&1 | tail -n 4
lantern-970: HTTP 400 {"error": "health must be one of active, at risk, lapsed"}
lantern-987: HTTP 400 {"error": "health must be one of active, at risk, lapsed"}
lantern-99: HTTP 400 {"error": "health must be one of active, at risk, lapsed"}
run 4: sent 0, removed 0, failed 284, retried after 429: 28
```

Every contact that became *new* was refused with `400`, and the error says why. Everything else went
through. Three properties of the script made that survivable:

- **A refused row is not remembered.** It stays out of `last_sent`, so the next run tries it again, and
  once somebody adds *new* to the CRM's picklist those rows go through without anybody resending
  anything by hand.
- **A refused row is printed and logged**, with the CRM's own explanation.
- **The run says how many failed.** A scheduled sync whose last line says `failed 0` every night and
  then does not is the alert; reading that line, or alerting on it, is the job.

The log answers what happened, run by run:

```
lantern=# SELECT run_id, action, http_status, count(*)
lantern-# FROM activation.sync_log GROUP BY 1, 2, 3 ORDER BY 1, 2, 3;
 run_id | action | http_status | count 
--------+--------+-------------+-------
      1 | upsert |         201 |  2649
      2 | upsert |         200 |     1
      3 | delete |         200 |     1
      4 | upsert |         400 |   284
(4 rows)
```

Run 1 created every contact, run 2 updated one, run 3 deleted one, and run 4's refusals are
there with their code. **A sync without a log is a sync nobody can debug**, because by the time somebody
notices a wrong field in the CRM, the request that wrote it is gone.

Change the view back by running `activation.sql` again — it starts the sync's memory from nothing too,
so the next run sends every contact again.
