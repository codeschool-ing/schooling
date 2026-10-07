---
title: A view as the interface
version: 1
---

The analysts also want age. Not a date of birth — nobody's analysis needs the day somebody was
born — but whether customers are young or old, and how that changes what they buy. Granting
`birth_date` would hand over the exact date for 6,012 people to answer a question about five
bands.

A **view** answers the question and keeps the date in the table:

```sql
-- What an analyst needs about a customer, computed where the data is.
-- The age band is derived here, so birth_date never leaves the table.
SET ROLE ipe_owner;
CREATE VIEW sales.customer_profile AS
SELECT customer_id,
       state,
       CASE WHEN age < 18 THEN 'under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 50 THEN '30-49'
            WHEN age < 70 THEN '50-69'
            ELSE '70+' END AS age_band,
       created_at::date AS customer_since
FROM (SELECT c.*, extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age
      FROM sales.customers c) c;
GRANT SELECT ON sales.customer_profile TO analyst;
```

```
ana@lab:~/gov$ psql -f view.sql
SET
CREATE VIEW
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT age_band, count(*) FROM sales.customer_profile GROUP BY 1 ORDER BY 1"
 age_band | count 
----------+-------
 18-29    |  1153
 30-49    |  2283
 50-69    |  1617
 70+      |   939
 under 18 |    20
(5 rows)

ana@lab:~/gov$ psql service=bruno -c "SELECT birth_date FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
```

The view computes the band on the server, and the date never reaches Bruno: he can read
`customer_profile` and still cannot read `birth_date` from the table. **The view is the interface
analysts get; the table is an implementation detail they never touch.** The lab's own today,
1 July 2026, is written into the view so that every run gives the same bands.

The bands also show something nobody asked for: **twenty customers are under eighteen.** A
pharmacy's terms of use may say customers are adults; the data says otherwise. Lesson 6 is about
what the LGPD asks for data about children and adolescents, and it starts from this line.

## Why a view can show what its reader cannot read

Bruno has no right to `birth_date`, and the view reads `birth_date`. It works because **a view
runs with its owner's privileges**, not its reader's. `ipe_owner` owns the view and can read the
whole table; Bruno is granted the view, and the view reads the table on his behalf. That is
exactly what makes a view useful as an interface, and section 8 shows the case where it is
exactly the problem.

## What makes a view a good interface

- **It exposes derived values, not raw ones**: an age band, a month, a state — what the
  question needs at the precision it needs.
- **It is named for its readers**, `customer_profile`, so a grant on it reads as a decision.
- **It is stable.** When the table gains a column, the view does not, until somebody decides
  the analysts should have it. Column privileges cannot do that: a new column is invisible until
  granted, and a granted `SELECT` on the table includes it the day it is added.

One limit is worth naming now. A view can hide the *columns* of individual rows; it cannot stop a
reader filtering until a group has one person in it. Lesson 5 measures that.
