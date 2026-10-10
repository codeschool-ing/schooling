---
title: Row-level security, and the same idea in SQL
version: 1
---

Lantern's sales manager for the South should see the South's numbers and nobody else's, in the same
report everybody else uses. Building a separate report per region is the answer that does not scale.
**Row-level security** is the one that does: the model itself filters rows according to who is
looking.

In Power BI it is a **role**, defined in Desktop under *Manage roles*, with a DAX filter on a table:

```
customers[region] = "South"
```

(Not run.) Anybody assigned to that role in the service sees the report as if a slicer on region were
fixed at South and hidden. Because the filter is on `customers`, it travels to `orders` along the
relationship like any other filter, and every measure respects it. Desktop's *View as* lets the
author check what a role sees before publishing — the step people skip, and then publish a report in
which the role sees nothing, or everything.

## The same idea in PostgreSQL

The database can do this too, and doing it once in SQL makes the mechanism visible. A table says who
may see which region, and a view joins through it using `current_user`, which inside a view is the
role running the query, not the view's owner:

```sql
CREATE TABLE semantic.region_access (role_name text, region text);
INSERT INTO semantic.region_access VALUES ('south_manager', 'South');
CREATE VIEW semantic.my_orders AS
SELECT o.*, c.region
FROM semantic.orders o
JOIN semantic.customers c USING (customer_id)
JOIN semantic.region_access a ON a.region = c.region AND a.role_name = current_user;
```

Then a role for the manager, allowed to read that view and nothing else:

```sql
CREATE ROLE south_manager LOGIN PASSWORD 'another-password-to-choose';
GRANT USAGE ON SCHEMA semantic TO south_manager;
GRANT SELECT ON semantic.my_orders TO south_manager;
```

```
lantern=# CREATE TABLE semantic.region_access (role_name text, region text);
CREATE TABLE

lantern=# INSERT INTO semantic.region_access VALUES ('south_manager', 'South');
INSERT 0 1

lantern=# CREATE VIEW semantic.my_orders AS
lantern-# SELECT o.*, c.region
lantern-# FROM semantic.orders o
lantern-# JOIN semantic.customers c USING (customer_id)
lantern-# JOIN semantic.region_access a ON a.region = c.region AND a.role_name = current_user;
CREATE VIEW

lantern=# CREATE ROLE south_manager LOGIN PASSWORD 'another-password-to-choose';
CREATE ROLE

lantern=# GRANT USAGE ON SCHEMA semantic TO south_manager;
GRANT

lantern=# GRANT SELECT ON semantic.my_orders TO south_manager;
GRANT
```

Connected as the manager, asking for every region:

```
ana@vm:~$ PGPASSWORD=another-password-to-choose psql -h localhost -U south_manager lantern -c 'SELECT region, count(*) FROM semantic.my_orders GROUP BY region'
 region | count 
--------+-------
 South  |  1126
(1 row)
```

Only the South's 1,126 orders arrive. The manager did not write a filter and cannot remove one: the
view applies it, and the role cannot read the tables underneath.

Two warnings apply to both versions. **A filter of this kind is only as good as the mapping table**:
a manager who moves to another region and stays in the table keeps seeing the old one. And **the
people who build the model see everything**, by design, so row-level security protects the readers
of a report from each other and not from its authors.
