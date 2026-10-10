---
title: Checking events against the plan, in SQL
version: 1
---

Lantern's plan has five events, one per step of the way to a purchase, and `web_events` has always
followed it. On 17 June 2026 a new version of the mobile app ships, and its events arrive in a staging
table before anything loads them into `web_events`. This file writes the plan as a table and plays the
app's first day — the course playing the app, as it plays the shop. Save it as `~/tracking.sql`:

```sql
-- tracking.sql: the tracking plan, and a day of events from the new mobile app.
DROP SCHEMA IF EXISTS tracking CASCADE;
CREATE SCHEMA tracking;

CREATE TABLE tracking.plan (
  event   text PRIMARY KEY,
  step    int UNIQUE NOT NULL,
  meaning text NOT NULL
);
INSERT INTO tracking.plan VALUES
  ('visit',        1, 'a session starts on any page'),
  ('product_view', 2, 'a product page is shown'),
  ('add_to_cart',  3, 'a product goes into the cart'),
  ('checkout',     4, 'the checkout page is shown'),
  ('purchase',     5, 'a payment is confirmed');

-- What arrived on 17 June 2026, the new app's first day. The app names one
-- event its own way, and sends some purchases twice when a slow network makes it retry.
CREATE TABLE tracking.incoming AS
SELECT e.session_id, s.device, e.happened_at,
       CASE WHEN s.device = 'mobile' AND e.event = 'add_to_cart' THEN 'addToCart'
            ELSE e.event END AS event
FROM shop.web_events e JOIN shop.web_sessions s USING (session_id)
WHERE e.happened_at >= '2026-06-17' AND e.happened_at < '2026-06-18';
INSERT INTO tracking.incoming
SELECT session_id, device, happened_at, event FROM tracking.incoming
WHERE device = 'mobile' AND event = 'purchase' AND session_id % 2 = 0;
```

```
ana@vm:~$ psql -q lantern -f tracking.sql
psql:tracking.sql:2: NOTICE:  schema "tracking" does not exist, skipping
```

Three checks, each a query a scheduled job could run every morning before the day's events are loaded.

**Events the plan does not have.** Every name that arrived, joined to the plan; the ones with no match:

```
lantern=# SELECT i.event, count(*) AS events
lantern-# FROM tracking.incoming i LEFT JOIN tracking.plan p USING (event)
lantern-# WHERE p.event IS NULL
lantern-# GROUP BY i.event;
   event   | events 
-----------+--------
 addToCart |     19
(1 row)
```

**Duplicates.** The same event, in the same session, at the same instant, more than once:

```
lantern=# SELECT event, count(*) AS events,
lantern-#        count(DISTINCT (session_id, happened_at)) AS distinct_events
lantern-# FROM tracking.incoming
lantern-# GROUP BY event
lantern-# HAVING count(*) > count(DISTINCT (session_id, happened_at));
  event   | events | distinct_events 
----------+--------+-----------------
 purchase |     19 |              14
(1 row)
```

**Steps out of order.** A step that arrived in a session without the step before it. The plan's `step`
column makes this one query rather than four:

```
lantern=# SELECT p.step, p.event, count(DISTINCT i.session_id) AS sessions_without_the_step_before
lantern-# FROM tracking.incoming i JOIN tracking.plan p USING (event)
lantern-# WHERE p.step > 1
lantern-#   AND NOT EXISTS (SELECT 1 FROM tracking.incoming j JOIN tracking.plan q USING (event)
lantern(#                   WHERE j.session_id = i.session_id AND q.step = p.step - 1)
lantern-# GROUP BY p.step, p.event ORDER BY p.step;
 step |  event   | sessions_without_the_step_before 
------+----------+----------------------------------
    4 | checkout |                               12
(1 row)
```

Each check found something, and together they tell one story.

- **`addToCart` is not in the plan**: 19 events, every add-to-cart the new app sent that day, under a name
  nobody agreed. Nothing is wrong with the app's code in its own terms; it disagrees with the plan.
- **Some purchases were sent twice**: 19 purchase events, 14 different ones. Five purchases would be
  counted twice in every report built on the raw table, which on a day of 14 is a third more purchases
  than happened.
- **Checkout arrived without the step before it** in 12 sessions. That is the rename seen from the
  funnel's side: the step before checkout is `add_to_cart`, and on mobile it no longer exists under that
  name.


None of these three queries knows anything about the app. They know the plan, which is the point of
writing it down.
