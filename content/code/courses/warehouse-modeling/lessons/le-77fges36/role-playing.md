---
title: One date table, several roles
version: 1
---

`fact_fulfilment` has four date keys: ordered, paid, shipped and delivered. All four point at
`dim_date`. A single physical dimension used in several roles in one fact table is a **role-playing
dimension**, and the date is nearly always the first one a warehouse meets.

The difficulty is in the query. A report that needs the day an order was placed *and* the day it
left has to join `dim_date` twice, and a column called `day_name` is now ambiguous. The common answer
is a view per role, so that each role has a name a person can read:

```sql
-- One date dimension, two roles: the day an order was placed, and the day it left.
CREATE VIEW dim_order_date AS SELECT * FROM dim_date;
CREATE VIEW dim_ship_date  AS SELECT * FROM dim_date;

SELECT od.day_name AS ordered_on, sd.day_name AS shipped_on, count(*) AS orders
FROM fact_fulfilment f
JOIN dim_order_date od ON od.date_key = f.ordered_date_key
JOIN dim_ship_date  sd ON sd.date_key = f.shipped_date_key
WHERE od.day_of_week = 5
GROUP BY ALL ORDER BY orders DESC;
```

```
ana@lab:~/wh$ duckdb wh.duckdb < roles.sql
┌────────────┬────────────┬────────┐
│ ordered_on │ shipped_on │ orders │
│  varchar   │  varchar   │ int64  │
├────────────┼────────────┼────────┤
│ Friday     │ Monday     │  17091 │
│ Friday     │ Tuesday    │  11170 │
│ Friday     │ Wednesday  │   5502 │
└────────────┴────────────┴────────┘
```

Orders placed on a Friday left on Monday more than on any other day, because the warehouse does not
despatch at weekends; most of the rest left on Tuesday. The two views cost nothing to store, since
each one is the same table under another name, and they make the query say which date it means at
every line.

**Use the role's name everywhere a person will see it.** A report tool shows `dim_ship_date.month_name`
as *Ship date › Month*, and nobody has to guess which of four dates a column belongs to. Some teams
rename the columns inside each view as well (`ship_month`, `order_month`) so that the role survives
even when the table name is not shown.

Other dimensions play roles too, wherever a fact refers to two things of the same kind: a transfer of
stock from one shop to another points at `dim_shop` twice, as the shop sending and the shop receiving.
