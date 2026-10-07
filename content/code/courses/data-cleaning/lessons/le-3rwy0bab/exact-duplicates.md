---
title: Exact duplicates: the same row twice
version: 1
---

**An exact duplicate is a row that repeats another in every column.** It is the easy kind, and it
is easy only once you have decided that two identical rows are one thing counted twice rather than
two things that happen to look alike. For a customer file with an id column that decision is
safe: two rows with the same id and the same everything are one customer.

Both tools count them the same way:

```
ana@lab:~/clean$ python -c "import pandas as pd; c = pd.read_csv('raw/customers.csv', dtype=str); print(c.duplicated().sum(), c['customer_id'].duplicated().sum())"
37 37
ana@lab:~/clean$ psql -c 'SELECT count(*) AS rows, count(DISTINCT c) AS distinct_rows FROM raw.customers c'
 rows | distinct_rows 
------+---------------
 2413 |          2376
(1 row)
```

`duplicated()` marks every row that repeats an earlier one, so its sum is the number of extra
copies: 37. The same 37 rows repeat their `customer_id`, which confirms that the copies are whole
rows and not two customers sharing an id. In SQL, `count(DISTINCT c)` counts distinct whole rows,
because `c` is the row itself; 2,413 rows and 2,376 distinct ones.

Removing them is `drop_duplicates()` in pandas and `SELECT DISTINCT` in SQL, and both keep one copy
of each. **Lesson 2's profile found these 37 before anybody went looking**, as the gap between
filled and distinct in `customer_id`.

## When you need to keep one on purpose

`DISTINCT` cannot choose which copy survives, which does not matter when the copies are identical.
When they are not, the tool is a window function that numbers the copies inside each key:

```
ana@lab:~/clean$ psql -c "SELECT order_id, total, row_number() OVER (PARTITION BY order_id ORDER BY order_id) AS copy FROM raw.orders WHERE order_id IN (SELECT order_id FROM raw.orders GROUP BY order_id HAVING count(*) > 1) ORDER BY order_id LIMIT 6"
 order_id | total | copy 
----------+-------+------
 102757   | 56.55 |    1
 102757   | 56.55 |    2
 102918   | 37.00 |    1
 102918   | 37.00 |    2
 105385   | 27.20 |    1
 105385   | 27.20 |    2
(6 rows)
```

Every repeated order appears with `copy` 1 and 2, and keeping `copy = 1` keeps one of each. With an
`ORDER BY` inside the window — the newest timestamp first, say — the same query keeps a chosen copy
instead of an arbitrary one, which is what the next section needs.
