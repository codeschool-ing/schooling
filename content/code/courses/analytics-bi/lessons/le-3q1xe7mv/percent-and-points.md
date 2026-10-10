---
title: Percent and percentage points
version: 1
---

Lantern's website conversion — sessions that ended in a purchase — by year:

```
lantern=# SELECT extract(year FROM started_at)::int AS year, count(*) AS sessions,
lantern-#        count(*) FILTER (WHERE steps >= 5) AS purchases,
lantern-#        round(100.0 * count(*) FILTER (WHERE steps >= 5) / count(*), 2) AS conversion_pct
lantern-# FROM shop.web_sessions
lantern-# GROUP BY 1 ORDER BY 1;
 year | sessions | purchases | conversion_pct 
------+----------+-----------+----------------
 2025 |    28194 |      2078 |           7.37
 2026 |    31806 |      2152 |           6.77
(2 rows)
```

From 7.37% to 6.77%. Two sentences describe that change, and both are correct:

- conversion **fell 0.60 percentage points**, the difference between the two rates;
- conversion **fell 8.1%**, the difference as a share of where it started: 0.60 divided by 7.37.

They are heard very differently. "Conversion fell 8%" in a meeting can be heard as eight points, which
would have taken conversion to almost nothing, and even heard correctly it sounds larger than "0.6
points". Whoever chose the relative version may not have meant to dramatise: many tools compute
*change %* by default.

Three habits prevent it:

- **Say "points" for a difference between two percentages**, and "percent" only for a relative change,
  and when it matters give both: *down 0.6 points, from 7.37% to 6.77%*.
- **Give the two levels**, not only the change. A reader who sees 7.37% and 6.77% cannot be misled by
  either sentence.
- **Beware of relative changes on small rates.** A refund rate that goes from 1% to 2% has *doubled*,
  which is true and is also one customer in a hundred.

This change also hides something bigger than the wording, which is the subject of the paradox section:
whether conversion fell at all.

The question that catches it: **is this change in points or in percent, and does the sentence say so?**
