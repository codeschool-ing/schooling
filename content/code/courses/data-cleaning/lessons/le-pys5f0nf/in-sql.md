---
title: In SQL
version: 1
---

```sql
WITH orders AS (
  SELECT DISTINCT * FROM raw.orders
), delivered AS (
  SELECT channel, greatest(total::numeric, 0) AS total,
         CASE WHEN channel = 'site'
              THEN ordered_at::timestamptz AT TIME ZONE 'America/Sao_Paulo'
              ELSE ordered_at::timestamp END AS placed
  FROM orders
  WHERE status = 'delivered'
)
SELECT channel, count(*) AS orders, sum(total) AS revenue,
       sum(total) FILTER (WHERE placed >= '2025-12-01') AS december
FROM delivered
GROUP BY channel
ORDER BY channel;
```

```
ana@lab:~/clean$ psql -f task.sql
 channel | orders |  revenue   | december  
---------+--------+------------+-----------
 app     |  11851 | 1065555.60 | 132925.45
 site    |  14659 | 1436387.75 | 281616.15
(2 rows)
```

Each clause of the task is one line of the query, in the order a reader would look for it:

- `SELECT DISTINCT *` removes the exact repeated rows, comparing every column.
- `greatest(total::numeric, 0)` turns a negative total into zero, and the cast to `numeric` keeps
  money exact, with no floating point anywhere.
- The `CASE` reads the two clocks. `ordered_at::timestamptz` understands the `Z` as UTC, and `AT TIME
  ZONE 'America/Sao_Paulo'` gives the local time; the app's times are already local and are only
  cast.
- `FILTER (WHERE placed >= '2025-12-01')` adds up December without a second query.

**SQL's strengths here are the ones lessons 10 and 11 relied on.** A cast that cannot read a value
stops the query rather than inventing a blank, the work happens where the data already is, and the
whole transformation is one text file that can be reviewed line by line. Its weakness shows in the
`WITH` clauses: a long cleaning becomes a long chain of named steps, which is readable at five and
hard work at fifty.
