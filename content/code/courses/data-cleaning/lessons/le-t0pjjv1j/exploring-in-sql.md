---
title: Exploring in SQL
version: 1
---

Most of this lesson's questions can be asked of the database directly, and for a first look at a
large table that is often the faster place: the data does not have to leave the server.

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(d.groupby('channel')['total'].agg(['size', 'median', 'mean']).round(2).to_string())"
          size  median   mean
channel                      
app      11851    57.5  89.75
site     14659    57.6  97.55
ana@lab:~/clean$ psql -c "SELECT channel, count(*), percentile_cont(0.5) WITHIN GROUP (ORDER BY total::numeric) AS median, round(avg(total::numeric), 2) AS mean FROM (SELECT DISTINCT * FROM raw.orders) o WHERE status = 'delivered' GROUP BY channel"
 channel | count | median | mean  
---------+-------+--------+-------
 app     | 11851 |   57.5 | 89.89
 site    | 14659 |  57.65 | 97.96
(2 rows)

ana@lab:~/clean$ psql -c "SELECT corr(n.items, o.total::numeric) AS pearson FROM (SELECT DISTINCT * FROM raw.orders) o JOIN (SELECT order_id, count(*) AS items FROM raw.order_items GROUP BY order_id) n USING (order_id) WHERE o.status = 'delivered'"
       pearson       
---------------------
 0.22300728275886414
(1 row)
```

The pandas line comes first, from the cleaned orders, so there is something to compare with. The
SQL query gives the same shape per channel in one line each; `percentile_cont(0.5) WITHIN GROUP
(ORDER BY ...)` is the median. In both, the medians of the two channels are almost equal while the
means differ by about R$ 8, which is the long tail again, mostly the sixteen corporate orders, all
placed on the site.

The two tools do not agree exactly, though: R$ 89.89 against R$ 89.75 for the app's mean, R$ 57.65
against R$ 57.60 for the site's median. That difference is worth understanding rather than
ignoring. These queries read `raw.orders`, so the
seven typed totals of lesson 9 are still at ten times their value and the negative totals are still
negative. **The median barely notices; the mean does.** A first look in SQL over raw tables is fine
for shapes and orders of magnitude, and every number that goes into a report comes from the cleaned
data.

The second query is Pearson's correlation, built into PostgreSQL as `corr`, between the number of
lines and the total: 0.223, against pandas' 0.224 on the cleaned totals. PostgreSQL has no
rank correlation built in. The ranks can be computed with `rank() OVER (ORDER BY ...)` and passed
to `corr`, which is exactly what pandas did a section ago.
