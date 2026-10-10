---
title: Holding the mix still
version: 1
---

Simpson's paradox is usually explained with a diagram and left there. It can also be measured, by asking
a precise question: **what would the total have been if the mix had not changed?** Compute each year's
rates on the same weights — first 2025's mix of devices, then 2026's:

```
lantern=# WITH r AS (
lantern(#   SELECT year, device, count(*)::numeric AS sessions,
lantern(#          count(*) FILTER (WHERE steps >= 5) / count(*)::numeric AS rate
lantern(#   FROM (SELECT extract(year FROM started_at)::int AS year, device, steps
lantern(#         FROM shop.web_sessions) s
lantern(#   GROUP BY 1, 2),
lantern-# w AS (SELECT year, device, sessions / sum(sessions) OVER (PARTITION BY year) AS share FROM r)
lantern-# SELECT 'mix of ' || w.year AS weights,
lantern-#        round(100 * sum(w.share * r.rate) FILTER (WHERE r.year = 2025), 2) AS rates_of_2025,
lantern-#        round(100 * sum(w.share * r.rate) FILTER (WHERE r.year = 2026), 2) AS rates_of_2026
lantern-# FROM w JOIN r USING (device)
lantern-# GROUP BY w.year ORDER BY w.year;
   weights   | rates_of_2025 | rates_of_2026 
-------------+---------------+---------------
 mix of 2025 |          7.37 |          7.92
 mix of 2026 |          6.32 |          6.77
(2 rows)
```

Read the table by rows. With 2025's mix, conversion goes from 7.37% to **7.92%**: the 2026 rates, on the
visitors of 2025, would have been better. With 2026's mix, from **6.32%** to 6.77%: better again. Holding
the mix still, either way, conversion rose by about half a point. The whole of the reported fall, and
more, is the change of mix.

That splits the reported −0.60 points into two parts somebody can act on:

- **the rates improved**, by about +0.5 points at a fixed mix — the website and its checkout got better;
- **the mix moved towards phones**, worth about −1.1 points — a fact about where the visitors come from,
  which is marketing's question, not the website's.

The two parts are not equally certain. The mix moved by fifteen points of share, on tens of thousands of
sessions, and that is not chance. The rates moved by less: desktop's 0.9 points is about two standard
errors, as lesson 9 would compute it, and mobile's 0.24 points about one. So the safe reading is *the
fall is the mix; the website is no worse and probably a little better*, not *the website improved*.

This is called **standardisation**, or a mix-adjusted rate, and it is the honest form of a comparison
between two periods whose populations differ. It needs the groups to be chosen for a reason — device here,
because the rates differ so much between them — and it needs the reader to be told which mix was held
still, because the two answers above differ by more than a point.
