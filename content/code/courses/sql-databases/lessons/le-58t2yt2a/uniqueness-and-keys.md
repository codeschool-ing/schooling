---
title: The indexes you already have, and the one you are missing
version: 2
---

Some of your indexes were never created by anybody. Declare a key and you get one:

```sql
CREATE TABLE customers (
    id    integer PRIMARY KEY,          -- a unique index on (id)
    email text UNIQUE                   -- a unique index on (email)
);
```

A uniqueness rule has to be checked on every insert, and checking it by scanning the table would be
unusable — so the rule is **implemented as** a unique index. That is why lesson 3's constraint and
this lesson's index are the same object seen from two sides, and why adding your own index on a
primary key column is pure waste.

## Nulls do not collide

```sql
INSERT INTO customers (id, email) VALUES (1, NULL);
INSERT INTO customers (id, email) VALUES (2, NULL);   -- accepted
```

Both rows go in. A unique index refuses two rows that are **equal**, and lesson 1 settled that two
unknowns are not known to be equal. So a nullable unique column permits any number of nulls, which
is usually what you want and is occasionally a surprise.

PostgreSQL 15 added the other behaviour, for when it is not:

```sql
CREATE UNIQUE INDEX ON customers (email) NULLS NOT DISTINCT;
```

## The one you are missing

> **PostgreSQL does not create an index for a foreign key. MySQL does.**

That single sentence is the most valuable thing in this lesson, because the missing index is
invisible until it is expensive.

```sql
CREATE TABLE orders (
    id          integer PRIMARY KEY,
    customer_id integer REFERENCES customers (id)      -- no index on customer_id
);
```

The `REFERENCES` gets you the constraint. The **parent** side is indexed, because `customers.id` is
a primary key. The child's `customer_id` has nothing, and three things suffer:

**Every lookup by customer.** `WHERE customer_id = 7` is a scan, and so is the join in every query
of the shape lessons 5 and 6 were built on. This one people find quickly.

**Every delete of a parent row.** Deleting a customer requires the database to prove no order
references them — which, with no index on `orders.customer_id`, means reading the whole `orders`
table. Deleting a hundred customers reads it a hundred times. This is the classic *"why does
deleting one row take four minutes"*, and the answer is never in the `DELETE`.

**And `ON DELETE CASCADE`**, which is the same work with more rows at the end of it.

MySQL avoids the whole problem by refusing: InnoDB creates an index on the referencing columns if
one does not exist. It is a small thing that prevents a large class of incident, and PostgreSQL
leaves it to you.

So: **index your foreign keys**, unless you have a reason not to. Finding the ones you have not:

```sql
SELECT c.conrelid::regclass AS "table", c.conname AS "constraint"
FROM   pg_constraint c
WHERE  c.contype = 'f'
AND    NOT EXISTS (
           SELECT 1 FROM pg_index i
           WHERE i.indrelid = c.conrelid
           AND   (i.indkey::smallint[])[0:array_length(c.conkey,1)-1] @> c.conkey
       );
```

Run it on any PostgreSQL database that has been alive for a year and it will find something.

## Constraint or index

In PostgreSQL the two are not quite interchangeable:

| | `UNIQUE` constraint | unique index |
|---|---|---|
| can be the target of a foreign key | yes | no |
| appears as a constraint in the catalogue | yes | no |
| can be partial (`WHERE …`) | no | **yes** |
| can be on an expression | no | **yes** |

Which decides it in practice. Use a constraint for plain uniqueness on a column, because it says
what it means and other tables can reference it. Use a unique index when you need the last two rows
of that table — *"unique among the rows that are not deleted"*, *"unique ignoring case"* — which is
the previous section's material.

An index built first can be promoted afterwards, which is how you add a unique constraint to a live
table without holding a lock while it builds:

```sql
CREATE UNIQUE INDEX CONCURRENTLY customers_email_key ON customers (email);
ALTER TABLE customers ADD CONSTRAINT customers_email_key UNIQUE USING INDEX customers_email_key;
```

## Two sharp edges

**Building a unique index on data that has duplicates fails.** That is correct, and it means the
statement you rehearsed on an empty staging database can fail on production. Find them first —
lesson 6's `GROUP BY … HAVING count(*) > 1` — and decide what to do with them before the migration,
not during it.

**A swap violates uniqueness halfway through.** Exchanging two rows' `position` values breaks the
rule between the first update and the second, and the statement is rejected even though the end
state is fine. The answer is to defer the check to the end of the transaction:

```sql
ALTER TABLE items ADD CONSTRAINT items_position_key UNIQUE (position) DEFERRABLE INITIALLY IMMEDIATE;

BEGIN;
SET CONSTRAINTS items_position_key DEFERRED;
UPDATE items SET position = 2 WHERE id = 1;
UPDATE items SET position = 1 WHERE id = 2;
COMMIT;                                     -- checked here, and it passes
```

Which is lesson 8's transaction doing something it is uniquely able to do: making the intermediate
state, which is invalid, invisible to the rule as well as to everybody else.
