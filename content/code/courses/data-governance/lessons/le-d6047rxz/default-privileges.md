---
title: Tables that do not exist yet
version: 1
---

Grants are made on objects that exist. A table created tomorrow starts the way every table
started in the first section — open to its owner and nobody else:

```sql
SET ROLE ipe_owner;
CREATE TABLE sales.returns (
  order_id    integer REFERENCES sales.orders,
  returned_on date    NOT NULL,
  reason      text    NOT NULL
);
```

```
ana@lab:~/gov$ psql -f new-table.sql
SET
CREATE TABLE
ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.returns"
ERROR:  permission denied for table returns
```

**That refusal is the safe default, and it is also a bug report in waiting.** A pipeline adds a
table, the dashboard that reads it fails on Monday morning, somebody fixes it in a hurry with the
widest grant that makes the error go away, and nobody revisits it.

PostgreSQL lets the owner say in advance what new objects should carry:

```sql
-- Whatever ipe_owner creates in `sales` from now on, analysts may read.
-- It changes nothing that exists already: that is what GRANT is for.
SET ROLE ipe_owner;
ALTER DEFAULT PRIVILEGES IN SCHEMA sales GRANT SELECT ON TABLES TO analyst;
GRANT SELECT ON sales.returns TO analyst;
CREATE TABLE sales.deliveries (
  order_id     integer REFERENCES sales.orders,
  delivered_at timestamptz
);
```

```
ana@lab:~/gov$ psql -f defaults.sql
SET
ALTER DEFAULT PRIVILEGES
GRANT
CREATE TABLE
ana@lab:~/gov$ psql -c "\ddp"
            Default access privileges
   Owner   | Schema | Type  |  Access privileges  
-----------+--------+-------+---------------------
 ipe_owner | sales  | table | analyst=r/ipe_owner
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.returns" -c "SELECT count(*) FROM sales.deliveries"
 count 
-------
     0
(1 row)

 count 
-------
     0
(1 row)
```

`\ddp` shows the rule: whatever `ipe_owner` creates as a table in `sales` is readable by
`analyst`. `deliveries`, created after the rule, was readable at once; `returns`, created before,
needed the ordinary `GRANT` in the same file. **A default privilege changes the future and never
the past**, which is the first thing that surprises everybody who uses one.

Two details decide whether it works:

- **The rule belongs to the role that creates the objects.** It reads "for tables `ipe_owner`
  creates". A table Ana created as herself would not be covered, which is one more reason the
  schema is changed under `SET ROLE ipe_owner` and never as a person.
- **Defaults should be as narrow as the grants they stand in for.** A default of `SELECT` for
  analysts on `sales` is a decision about `sales`. The same rule on the `health` schema would
  mean that every future table of medical data opens itself to every analyst on the day it is
  created — the decision made once, years earlier, by somebody thinking about a different table.
