---
title: Privileges on a column
version: 1
---

The analysts need customers for almost every question they ask — sales by state, new customers
per month, how many accepted marketing. None of those needs a name, an e-mail address, a CPF or
a date of birth. Today they have nothing at all on the table:

```
ana@lab:~/gov$ psql service=bruno -c "SELECT * FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
```

Granting `SELECT` on the table would answer every analytic question and hand four columns of
identifying data to everybody in the job. PostgreSQL can grant a verb **on named columns**
instead:

```sql
-- Analysts see who the customers are as a population, never as people.
SET ROLE ipe_owner;
GRANT SELECT (customer_id, sex, city, state, created_at, marketing_opt_in)
  ON sales.customers TO analyst;
```

```
ana@lab:~/gov$ psql -f columns.sql
SET
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT * FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
ana@lab:~/gov$ psql service=bruno -c "SELECT state, count(*) FROM sales.customers GROUP BY state ORDER BY 2 DESC LIMIT 5"
 state | count 
-------+-------
 SP    |  2322
 RJ    |  1064
 MG    |   468
 PR    |   390
 RS    |   318
(5 rows)

ana@lab:~/gov$ psql service=bruno -c "SELECT email FROM sales.customers LIMIT 1"
ERROR:  permission denied for table customers
ana@lab:~/gov$ psql -c "\dp sales.customers"
                                      Access privileges
 Schema |   Name    | Type  |      Access privileges      |   Column privileges   | Policies 
--------+-----------+-------+-----------------------------+-----------------------+----------
 sales  | customers | table | ipe_owner=arwdDxt/ipe_owner+| customer_id:         +| 
        |           |       | pipeline=r/ipe_owner       +|   analyst=r/ipe_owner+| 
        |           |       | support_agent=r/ipe_owner   | sex:                 +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | city:                +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | state:               +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | created_at:          +| 
        |           |       |                             |   analyst=r/ipe_owner+| 
        |           |       |                             | marketing_opt_in:    +| 
        |           |       |                             |   analyst=r/ipe_owner | 
(1 row)
```

Three answers, one rule:

- **`SELECT *` is refused.** The star asks for every column, including the ones not granted, and
  the server refuses the whole statement rather than quietly returning a subset. That is the
  right behaviour — a query that silently drops columns would be a query that lies — and it is
  also the first thing an analyst trips over. The answer is to name the columns.
- **Naming granted columns works**, and the analysis Bruno needed runs: São Paulo has 2,322 of
  Ipê's customers.
- **Naming one that was not granted is refused**, with the same message.

`\dp` now lists the six columns one by one under **Column privileges**, beside the table-wide
grants to `pipeline` and `support_agent`. That listing is the document an auditor asks for: the
columns of `sales.customers` an analyst can see, granted by whom.

## What column privileges are good for, and what they are not

**They are a filter on what can be selected, not on what can be inferred.** Bruno can count
customers by `state`, `city` and `sex`, and group them by month of sign-up. Lesson 5 shows how
few of those combinations it takes before a group has one person in it, at which point a
"population" query describes somebody. Column privileges keep the CPF out of Bruno's results.
They do not, on their own, make what is left anonymous.

**They are also awkward to live with.** Every new column needs a decision, `SELECT *` fails in
every tool that writes it, and the grants are invisible to whoever reads only the table-level
`\dp`. The usual way out is the subject of the next section: give analysts a view that already
has the right columns, computed the right way, and grant that.
