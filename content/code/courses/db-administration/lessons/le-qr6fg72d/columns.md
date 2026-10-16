---
title: Privileges on columns
version: 1
---

`SELECT`, `INSERT`, `UPDATE` and `REFERENCES` can be granted on **a list of columns instead of the
whole table**. That is how an analyst reads the customers without reading their e-mail addresses:
the table stays one table, and the column the analyst does not need is simply not in his grant.

```
shop=# GRANT SELECT (id, name, country, created_at) ON customers TO reporting;
GRANT
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT * FROM customers LIMIT 1;
ERROR:  permission denied for table customers

shop=> SELECT id, name, country FROM customers ORDER BY id LIMIT 3;
 id |    name    | country 
----+------------+---------
  1 | Customer 1 | PT
  2 | Customer 2 | AR
  3 | Customer 3 | MX
(3 rows)
shop=# \dp customers
                               Access privileges
 Schema |   Name    | Type  | Access privileges | Column privileges | Policies 
--------+-----------+-------+-------------------+-------------------+----------
 public | customers | table |                   | id:              +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | name:            +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | country:         +| 
        |           |       |                   |   reporting=r/ana+| 
        |           |       |                   | created_at:      +| 
        |           |       |                   |   reporting=r/ana | 
(1 row)
```

`SELECT *` asks for every column, `email` among them, and is refused as a whole; **the error names
the table and not the column**, which sends people looking for a missing table grant. Listing the
granted columns works. `\dp` keeps column grants in a column of their own, one entry per column,
with `r` for read.

## A column REVOKE does not undo a table GRANT

The two kinds of grant are stored separately, and a role holds the union. So the obvious way to hide
one column from somebody who can read the table does nothing at all:

```
shop=# GRANT SELECT ON customers TO app;
GRANT

shop=# REVOKE SELECT (email) ON customers FROM app;
REVOKE
ana@db:~$ psql -h localhost -U app shop
shop=> SELECT email FROM customers ORDER BY id LIMIT 1;
         email         
-----------------------
 customer1@example.com
(1 row)
shop=# REVOKE SELECT ON customers FROM app;
REVOKE
```

The `REVOKE` succeeded, because there was nothing to revoke: `app` held no column grant on `email`,
it held the table. **To hide a column, revoke the table privilege and grant the columns you want
to keep**, as `reporting` was given above.

## UPDATE on a column, and the WHERE that needs SELECT

A column grant for `UPDATE` lets a role change some columns and not others: an application that
marks orders as shipped has no business changing what they cost. Grant `app` the `status` column
alone and try it, inside transactions that are rolled back:

```
shop=# GRANT UPDATE (status) ON orders TO app;
GRANT
ana@db:~$ psql -h localhost -U app shop
shop=> BEGIN;
BEGIN

shop=*> UPDATE orders SET status = 'shipped' WHERE id = 1;
ERROR:  permission denied for table orders

shop=!> ROLLBACK;
ROLLBACK

shop=> BEGIN;
BEGIN

shop=*> UPDATE orders SET status = 'shipped';
UPDATE 1000000

shop=*> ROLLBACK;
ROLLBACK
shop=# REVOKE UPDATE (status) ON orders FROM app;
REVOKE
```

The careful statement was refused and the catastrophic one went through. **`WHERE id = 1` reads the
column `id`, and reading needs `SELECT` on it**, which `app` does not have; the statement with no
`WHERE` reads nothing and changed all million rows. The same goes for `RETURNING` and for any
column used on the right-hand side of `SET`. An `UPDATE` grant almost always travels with a
`SELECT` grant on the columns that find the row, and a grant that seems to work only "without the
`WHERE`" is this, not a bug.
