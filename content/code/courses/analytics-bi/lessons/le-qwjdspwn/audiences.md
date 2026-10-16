---
title: An audience is a model with a filter
version: 1
---

The products' screens for marketing are built around the **audience**: a list of customers chosen by
rules — office customers, at risk, worth more than some amount — kept up to date and sent to a tool. In
a composable product an audience is built on top of a model somebody in data wrote, with filters a
marketer chooses from menus. Underneath, it is a `WHERE` clause.

Lantern's office customers, by health:

```
lantern=# SELECT health, count(*) AS customers, sum(net_revenue) AS net_revenue
lantern-# FROM activation.crm_contacts
lantern-# WHERE segment = 'office'
lantern-# GROUP BY health ORDER BY 2 DESC;
 health  | customers | net_revenue 
---------+-----------+-------------
 active  |       102 |   204917.62
 at risk |        43 |    87377.11
 lapsed  |        42 |    63526.32
(3 rows)
```

Forty-three office customers are *at risk*: they ordered in the last 120 days and not in the last 45,
and between them they have spent R$ 87,377.11 over the shop's life. That is the list the person who
calls office customers wants. Written down, it is a view:

```sql
CREATE VIEW activation.office_win_back AS
SELECT external_id, net_revenue, last_order
FROM activation.crm_contacts
WHERE segment = 'office' AND health = 'at risk';
```

```
lantern=# CREATE VIEW activation.office_win_back AS
lantern-# SELECT external_id, net_revenue, last_order
lantern-# FROM activation.crm_contacts
lantern-# WHERE segment = 'office' AND health = 'at risk';
CREATE VIEW

lantern=# SELECT count(*) AS customers, sum(net_revenue) AS net_revenue,
lantern-#        min(last_order) AS earliest, max(last_order) AS latest
lantern-# FROM activation.office_win_back;
 customers | net_revenue |  earliest  |   latest   
-----------+-------------+------------+------------
        43 |    87377.11 | 2026-02-19 | 2026-05-02
(1 row)
```

Forty-three customers, with last orders between 19 February and 2 May: exactly the window the
definition draws. Three properties make it an audience rather than an export:

- **It is a definition, not a list.** Tomorrow some of those 43 order again and leave it, and others
  cross the 45-day line and join it, without anybody rebuilding anything.
- **It inherits its words.** *At risk* and *net revenue* mean what lesson 2 and lesson 3 said, because
  the audience is built on `crm_contacts`, which is built on the semantic layer.
- **It is sent like any model.** Through lesson 7's sync, to the CRM as a list or as a field on each
  contact, with the same diff, the same key and the same delete — a customer who leaves the audience is
  a row that left the model.

What the products add is the menu: a marketer can build `segment = 'office' AND health = 'at risk'`
without writing it, and preview how many people it holds before sending it anywhere. What they cannot
add is the definition of *at risk*. If that is not in a model already, the menu offers whatever columns
exist, and every marketer builds their own.
