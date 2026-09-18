---
title: WITH, which is the same query with the steps named
version: 1
---

Here is the nested query from two sections ago, and here it is again:

```sql
SELECT * FROM (
    SELECT * FROM (
        SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
    ) a WHERE a.n > 3
) b JOIN customers c ON c.id = b.customer_id;
```

```sql
WITH per_customer AS (
    SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id
),
frequent AS (
    SELECT * FROM per_customer WHERE n > 3
)
SELECT c.name, f.n
FROM   frequent f
JOIN   customers c ON c.id = f.customer_id;
```

Longer, and it is the version you want at four in the afternoon six months from now. It reads top
to bottom in the order the work happens, each step has a name that says what it is, and no part of
it requires holding three levels of bracket in your head.

That is the whole feature. A **common table expression** is a named subquery written before the
statement that uses it, and it computes nothing a derived table could not.

## The syntax

```sql
WITH a AS (SELECT …),
     b AS (SELECT … FROM a …),
     c AS (SELECT … FROM a JOIN b …)
SELECT * FROM c;
```

One `WITH`, then a comma between each definition and none before the final statement. **A later
definition may use an earlier one**, which is what lets a query be a sequence of steps; an earlier
one may not use a later one.

The final statement does not have to be a `SELECT`. `INSERT`, `UPDATE` and `DELETE` all take a
`WITH` in front, which is how a complicated `DELETE` gets readable:

```sql
WITH stale AS (
    SELECT id FROM sessions WHERE last_seen < now() - INTERVAL '90 days'
)
DELETE FROM sessions WHERE id IN (SELECT id FROM stale);
```

PostgreSQL has had this since 8.4, SQLite since 3.8.3, MySQL from 8.0 and MariaDB from 10.2. It is
safe to assume today, and it is the reason a lot of SQL written before 2018 looks worse than it
needed to.

## The thing a derived table cannot do

Refer to the same step twice without writing it twice:

```sql
WITH monthly AS (
    SELECT date_trunc('month', ordered_on) AS month, sum(total) AS revenue
    FROM   orders
    GROUP BY 1
)
SELECT   this.month, this.revenue, prev.revenue AS previous
FROM     monthly this
LEFT JOIN monthly prev ON prev.month = this.month - INTERVAL '1 month';
```

`monthly` is defined once and used twice. As a derived table that is the same twenty lines written
out twice, and the second copy is the one somebody forgets to change.

Being able to name it does not mean it is computed once — that is the next section, and it is the
one piece of folklore in this lesson worth taking apart.

## Writing one that is worth having

The names are the point, so they have to carry information. `t1`, `t2`, `sub` and `data` throw the
feature away and leave you with a longer nested query.

```sql
WITH paid_orders   AS (…),
     monthly_totals AS (…),
     growth         AS (…)
SELECT * FROM growth;
```

A person can read those four lines and know what the query does without reading any of the bodies.
That is the test: **if the list of names does not describe the query, rename them.**

Two more habits worth having. Keep each step doing one thing — a CTE that groups and joins and
filters and ranks is a nested query with a name on it. And when a step is worth checking, you can
run it on its own by selecting from it, which is the practical reason this form is easier to debug
than the nested one.

## Data-modifying CTEs

PostgreSQL allows something the others do not, and it is genuinely useful:

```sql
WITH moved AS (
    DELETE FROM sessions
    WHERE  last_seen < now() - INTERVAL '90 days'
    RETURNING *
)
INSERT INTO sessions_archive SELECT * FROM moved;
```

Delete and archive in one statement, with `RETURNING` handing the deleted rows to the insert. The
rows are moved or the statement fails; there is no window in which they are in neither table.

One rule governs the whole thing, and it surprises people: **every part of the statement sees the
same snapshot of the data.** A `SELECT` in one CTE does not see rows an `UPDATE` in a sibling CTE
wrote. They are not steps in a program, however much the layout suggests it — they are parts of one
statement, and the order they run in is not defined. Two CTEs that both modify the same row are a
query whose result you cannot reason about.

MySQL and SQLite do not allow `INSERT`, `UPDATE` or `DELETE` inside a `WITH`. There it is two
statements in a transaction, which is lesson 8.
