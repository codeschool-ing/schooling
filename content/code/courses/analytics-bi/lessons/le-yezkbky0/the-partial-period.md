---
title: The partial period, and the date the data ends
version: 1
---

The last section ended on June 2026 at −45.9% against May. A reader who sees that on a Monday tile
calls a meeting. Before anyone does, the dashboard has to say one thing it usually leaves out: **when
the data ends**.

```
lantern=# SELECT max(order_date) AS data_until FROM semantic.orders;
 data_until 
------------
 2026-06-17
(1 row)
```

17 June. June has 30 days, and the tile compared 17 of them with 31 of May's. The comparison that
means something puts the same days side by side:

```sql
SELECT sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-06-01' AND '2026-06-17') AS june_1_to_17,
       sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-17') AS may_1_to_17,
       sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-31') AS may_whole
FROM semantic.orders;
```

```
lantern=# SELECT sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-06-01' AND '2026-06-17') AS june_1_to_17,
lantern-#        sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-17') AS may_1_to_17,
lantern-#        sum(net_revenue) FILTER (WHERE order_date BETWEEN '2026-05-01' AND '2026-05-31') AS may_whole
lantern-# FROM semantic.orders;
 june_1_to_17 | may_1_to_17 | may_whole 
--------------+-------------+-----------
     75811.94 |    82271.16 | 140097.06
(1 row)
```

The first seventeen days of June against the first seventeen of May: R$ 75,811.94 against R$
82,271.16, about 8% lower. That is worth noticing — and it is a different conversation from the one
−45.9% would have started. Whether 8% is a real slowdown or the noise of two short periods is a
question for next week's data, not for a headline.

Three habits remove the trap for good:

- **Show "data until" on the page**, from the data itself — `max(order_date)` — and never from the
  calendar. On the day a load fails, the calendar says today and the data says yesterday, and only the
  second is true.
- **Compare a partial period with the same part of the previous one** — month to date against the
  same days last month — or leave the current period off the trend until it is complete. The layer's
  `calendar` has a `month_is_complete` column for exactly that filter.
- **Mark the partial bar** when it has to be shown: a lighter shade, a dashed outline, a label saying
  "to 17 June". Lesson 10 returns to this as one of the ways a true chart misleads.
