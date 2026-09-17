---
title: A view is a query with a name, not a table
version: 1
---

```sql
CREATE VIEW active_customers AS
SELECT c.*
FROM   customers c
WHERE  c.deleted_at IS NULL
  AND  EXISTS (SELECT 1 FROM orders o
               WHERE o.customer_id = c.id AND o.placed_at > now() - INTERVAL '1 year');
```

```sql
SELECT count(*) FROM active_customers;
```

The second statement looks like it reads a table. It does not: **the view stores no rows.** The
database substitutes the definition and runs it, every time, against the data as it is now. Nothing
was copied and nothing can be stale.

That one sentence answers most questions about views. The other kind — the one that does store
rows — is the next section, and keeping the two apart is the entire skill here.

## What they are worth having for

**A definition that stops being argued about.** *"Active customer"* is a business rule, and the
moment it is written in four reports it is written four slightly different ways. One view, one
definition, and a change to it reaches everybody at once. That is the strongest reason and it has
nothing to do with the database.

**Permissions.** A view can expose some columns of a table and not others:

```sql
CREATE VIEW staff_directory AS SELECT id, name, department FROM employees;
GRANT SELECT ON staff_directory TO reporting;
```

`reporting` reads the directory and has no grant on `employees`, so salaries are unreachable. This
is the standard way to give somebody a narrow window onto a wide table.

**A rename that does not break anything.** Lesson 3 said renaming a column is a three-deploy change
because two versions of the application run at once. A view is one way to buy the time:

```sql
ALTER TABLE customers RENAME COLUMN nome TO name;
CREATE VIEW customers_old AS SELECT *, name AS nome FROM customers;
```

Old code reads the view, new code reads the table, and the view is dropped when the last old copy
is gone.

## The columns are fixed when it is created

Lesson 4 warned about `SELECT *` in a view and promised the demonstration here:

```sql
CREATE VIEW everything AS SELECT * FROM products;
ALTER TABLE products ADD COLUMN weight numeric;

SELECT * FROM everything;      -- the new column is not there
```

The `*` was expanded into a column list at creation. The view has the columns the table had that
day, and it keeps them until somebody recreates it. There is no error and no notice — a report
built on the view simply never learns about `weight`.

`CREATE OR REPLACE VIEW` does not rescue you either: it will add columns at the end, and it refuses
to remove one, rename one or change an order. To change the shape you drop and recreate, and
anything that depends on the view has to be dropped first. **Write the column list out.** The three
seconds it costs are the cheapest in this course.

## Views you can write to

A view over one table, with no aggregate, no `DISTINCT`, no `GROUP BY` and no window, is
automatically updatable — `INSERT`, `UPDATE` and `DELETE` on it reach the table underneath.

There is a sharp edge:

```sql
CREATE VIEW cheap_products AS SELECT * FROM products WHERE price < 100;
UPDATE cheap_products SET price = 500 WHERE id = 7;
```

That succeeds, and the row disappears from the view — you updated a row out of the set the view
defines. If that should not be allowed, say so when you create it:

```sql
CREATE VIEW cheap_products AS SELECT * FROM products WHERE price < 100
WITH CHECK OPTION;
```

Now the `UPDATE` is rejected. For a view too complicated to be updatable automatically, PostgreSQL
lets you write `INSTEAD OF` triggers and define what a write means — worth knowing it exists, and
worth a long look before you use it, because a table that is not a table and a write that is not a
write is a lot of surprise for one name.

## What they hide

A view is a query, so a view over a view over a view is one large query, and the planner expands
the lot before it decides anything. Usually that is fine and the pushdown from the derived-tables
section applies unchanged.

It stops being fine at the same place: a layer with a `DISTINCT`, a window function or a `GROUP BY`
is a wall that a filter from outside cannot cross. So `SELECT * FROM summary_view WHERE id = 7`
reads like an indexed lookup and can be a full aggregation of the table. **The view hides the cost,
not the work**, and this is the most common way a query that looks trivial turns out to take nine
seconds.

## And one thing a plain view does not guarantee

If you use a view for permissions, know that an ordinary view is not a wall. A user who can call a
function can write:

```sql
SELECT * FROM staff_directory WHERE leak(salary_hint);
```

and the planner may evaluate the cheap function before the view's own conditions, so rows the view
was meant to hide reach it. PostgreSQL's answer is `WITH (security_barrier = true)` on the view, or
row-level security on the table itself, which is the stronger tool. If a view is holding a security
boundary rather than a convenience, that distinction is the one to look up before you rely on it.
