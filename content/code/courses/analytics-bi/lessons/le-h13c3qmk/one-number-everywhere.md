---
title: The same number, whoever asks
version: 1
---

The point of the layer is that a question has one answer. Net revenue for the first quarter of
2026, asked of `semantic.orders`, then asked again after switching the session to UTC:

```
lantern=# SELECT sum(net_revenue) FROM semantic.orders
lantern-# WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
    sum    
-----------
 294209.60
(1 row)

lantern=# SET timezone = 'UTC';
SET

lantern=# SELECT sum(net_revenue) FROM semantic.orders
lantern-# WHERE order_date BETWEEN '2026-01-01' AND '2026-03-31';
    sum    
-----------
 294209.60
(1 row)
```

R$ 294,209.60 both times — the same figure finance reached in lesson 2's bridge, to the cent,
because the layer applies the same five parts. And the time zone did not move it. Lesson 2 showed
that the same question asked of `shop.orders` changes when the session's zone changes, because
`ordered_at::date` is computed in whatever zone the session is in. The layer's `order_date` is
computed with `AT TIME ZONE 'America/Sao_Paulo'` written into the view, so **the definition holds
even for a client that sets its own time zone** — which BI tools do, and which is exactly where a
setting on the database stops being enough.

That is the test to apply to anything in a layer: **ask it the way a careless client would.** A
session in another time zone, a join to another table, a filter forgotten. The answers that stay
put are definitions; the ones that move are still somebody's habit.

The region mapping passes the same test for a different reason. It is a table now, so a chart by
region in Metabase and a query by region in `psql` both read the same seven rows, and there is no
second `CASE` anywhere to disagree with it.
