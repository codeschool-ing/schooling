---
title: Reshaping in SQL
version: 1
---

PostgreSQL has no `PIVOT` or `UNPIVOT` keyword. Both moves are still short, and writing them out
has the merit of making every column visible.

**Unpivoting** is a join to a small table of values, built per row with `CROSS JOIN LATERAL`. Each
pair names a month and the column it comes from:

```sql
SELECT t.loja, m.month, m.target::int AS target
FROM raw.targets_2025 t
CROSS JOIN LATERAL (VALUES
  ('2025-01', t."jan/25"), ('2025-02', t."fev/25"), ('2025-03', t."mar/25"),
  ('2025-04', t."abr/25"), ('2025-05', t."mai/25"), ('2025-06', t."jun/25"),
  ('2025-07', t."jul/25"), ('2025-08', t."ago/25"), ('2025-09', t."set/25"),
  ('2025-10', t."out/25"), ('2025-11', t."nov/25"), ('2025-12', t."dez/25")
) AS m(month, target)
ORDER BY t.loja, m.month;
```

`Total` is not in the list, so it cannot melt by accident: in SQL **the columns to unpivot are
named one by one**, which is more typing and one less trap. The month is written as `2025-01`,
which sorts correctly as text and matches what `to_char(date, 'YYYY-MM')` gives on the sales side.

Saved as a view, it can be checked the same way as the pandas result, by its rows and its sum:

```
ana@lab:~/clean$ psql -c "CREATE VIEW targets_long AS $(cat unpivot.sql | tr -d ';')"
CREATE VIEW
ana@lab:~/clean$ psql -c 'SELECT count(*), sum(target) FROM targets_long'
 count |   sum   
-------+---------
    72 | 3801000
(1 row)

ana@lab:~/clean$ psql -c "SELECT * FROM targets_long WHERE loja = 'Batel' LIMIT 3"
 loja  |  month  | target 
-------+---------+--------
 Batel | 2025-01 |  14000
 Batel | 2025-02 |  14000
 Batel | 2025-03 |  14000
(3 rows)
```

72 rows and R$ 3,801,000, the same two numbers as in pandas.

**Pivoting** is conditional aggregation: one `sum(...) FILTER (WHERE ...)` per column you want,
grouped by the row you want.

```
ana@lab:~/clean$ psql -c "SELECT loja, sum(target) FILTER (WHERE month = '2025-01') AS jan, sum(target) FILTER (WHERE month = '2025-02') AS feb, sum(target) FILTER (WHERE month = '2025-03') AS mar, sum(target) AS year FROM targets_long GROUP BY loja ORDER BY year DESC"
   loja    |  jan   |  feb   |  mar   |  year   
-----------+--------+--------+--------+---------
 Online    | 180000 | 180000 | 180000 | 2286000
 Pinheiros |  52000 |  52000 |  52000 |  660000
 Botafogo  |  23000 |  23000 |  23000 |  294000
 Savassi   |  16000 |  16000 |  16000 |  204000
 Cambuí    |  14000 |  14000 |  14000 |  180000
 Batel     |  14000 |  14000 |  14000 |  177000
(6 rows)
```

The `FILTER` clause decides which rows each column adds up. Like `pivot_table`, it aggregates
whatever matches, so the same caution applies: the grain of the source decides whether `sum` is
the right function. Unlike `pivot_table`, every column is written by hand, which suits a report
with a fixed set of months and does not suit a set of columns that grows. For that, the long table
is the one to keep, and the wide one is produced at the last step, by whatever draws the report.
