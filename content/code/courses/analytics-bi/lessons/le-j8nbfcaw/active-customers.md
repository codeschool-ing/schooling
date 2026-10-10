---
title: How many active customers, and active how
version: 1
---

"Active customers" is the metric every subscription and repeat-purchase business asks for, and it
has no natural definition. It needs a window: active means did something in the last *N* days, as
of some date. Asked of Lantern on 31 May 2026, with three windows:

```
lantern=# SELECT count(DISTINCT customer_id) FILTER (WHERE ordered_at >= date '2026-06-01' - 30) AS last_30_days,
lantern-#        count(DISTINCT customer_id) FILTER (WHERE ordered_at >= date '2026-06-01' - 90) AS last_90_days,
lantern-#        count(DISTINCT customer_id) AS ever_ordered
lantern-# FROM orders
lantern-# WHERE ordered_at < '2026-06-01' AND customer_id <> 1;
 last_30_days | last_90_days | ever_ordered 
--------------+--------------+--------------
          705 |         1308 |         2482
(1 row)
```

705, 1,308 or 2,482, from the same table, on the same day. **The window is the definition**, and
the choice is not arbitrary: it should match how often a normal customer buys. The days between
one order and the same customer's next say how often that is:

```
lantern=# SELECT percentile_cont(ARRAY[0.25, 0.5, 0.75]) WITHIN GROUP (ORDER BY gap) AS days_between_orders
lantern-# FROM (SELECT ordered_at::date - lag(ordered_at::date) OVER (PARTITION BY customer_id ORDER BY ordered_at) AS gap
lantern(#       FROM orders WHERE customer_id <> 1) AS g
lantern-# WHERE gap IS NOT NULL;
 days_between_orders 
---------------------
 {16,27,45}
(1 row)
```

Half the gaps are longer than 27 days, and a quarter longer than 45. **A 30-day window therefore
counts a large share of perfectly regular customers as gone** — anyone who happens to be in a
35-day gap on the 31st. A 90-day window is twice the length of three gaps in four, and
is closer to the shop's rhythm.
"Ever ordered" is not an activity measure at all: it only grows, and it would report the shop's
best month on the day the last customer left.

Two details belong in the definition and are easy to leave out:

- **Which action counts.** Here it is placing an order. A shop that counts logging in, opening an
  e-mail or visiting the site gets a larger and less meaningful number.
- **The "as of" date.** `date '2026-06-01' - 30` is 2 May, so the first column counts customers
  with an order from 2 May to 31 May. A dashboard that computes "the last 30 days" from today moves
  every morning, and two people who looked at it on different days quote different numbers. A
  monthly report fixes the date at the end of the month.

The test account is excluded here too. One customer makes no visible difference to 1,308; it is
excluded because the definition says so, and a definition that is applied only when it matters is
not a definition.
