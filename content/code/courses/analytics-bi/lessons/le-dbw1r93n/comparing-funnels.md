---
title: Comparing a funnel over time
version: 1
---

In January 2026 Lantern changed its checkout page. Did it work? The funnel's last step is the one the
change touches — sessions that reached checkout and then paid — and it can be compared before and after,
by device:

```
lantern=# SELECT extract(year FROM started_at)::int AS year, device,
lantern-#        count(*) FILTER (WHERE steps >= 4) AS checkouts,
lantern-#        round(100.0 * count(*) FILTER (WHERE steps >= 5)
lantern(#              / count(*) FILTER (WHERE steps >= 4), 1) AS checkout_to_purchase
lantern-# FROM shop.web_sessions
lantern-# GROUP BY 1, 2 ORDER BY 1, 2;
 year | device  | checkouts | checkout_to_purchase 
------+---------+-----------+----------------------
 2025 | desktop |      1905 |                 77.1
 2025 | mobile  |       974 |                 62.6
 2026 | desktop |      1526 |                 80.0
 2026 | mobile  |      1451 |                 64.2
(4 rows)
```

On both devices the checkout step improved: desktop from 77.1% to 80.0%, mobile from 62.6% to 64.2%.
Whether that is the new page or chance depends on how many checkouts each rate rests on. A rate's
standard error is the square root of *p*(1 − *p*)/*n*, and for a difference of two rates the two squares
add: on desktop, about 1.4 points, so the 2.9-point rise is about two standard errors — likely real, not
certain. On mobile, with 974 checkouts in 2025, it is 2.0 points, and the 1.6-point rise is inside it.
Two rises in the same direction are more convincing than either alone, but the honest summary is
*desktop probably improved, mobile cannot be told yet*.

This is the right way to judge a change to one step: **compare that step, within each kind of session,
before and after.** It isolates the change from everything else that moved in 2026, and Lantern's
traffic in 2026 is not its traffic in 2025: far more of it arrives from social media and on phones,
which the next lesson measures.

That shift matters as soon as somebody compares the *whole site's* conversion between the two years,
because the mix of sessions behind each year's number is different. What happens then is the subject of
the next lesson, and it is one of the most reliable ways there is to reach the wrong conclusion from
correct numbers. For now, the rule: **when the mix of what you are counting changes, compare within the
parts before you compare the total.**
