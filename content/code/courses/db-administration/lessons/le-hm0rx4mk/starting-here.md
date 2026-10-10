---
title: Where this lesson starts
version: 1
---

This lesson starts where lesson 12 ended. Four roles: **`shop_owner`**, who owns the database,
both tables, the `reports` schema and its view, and never logs in; **`app`**, who reads and writes
rows; **`reporting`**, a group that reads orders and every customer column but `email`; and
**`bruno`**, an analyst in that group. `CONNECT` on `shop` is revoked from `PUBLIC` and granted to
`app` and `reporting`. If you followed lesson 12 on your server, all of it is there, and the check
at the end of this section should match what you have.

If you are starting here, connect to `shop` as `ana` with `psql shop` and run this, which is
lesson 11's roles, the schema and view lesson 12 made, and lesson 12's `layout.sql`, in that order:

```sql
-- where lesson 13 starts: lessons 11 and 12 together, run in shop as ana
CREATE ROLE reporting;
CREATE ROLE bruno LOGIN IN ROLE reporting;
CREATE ROLE app LOGIN;

CREATE SCHEMA reports;
CREATE VIEW reports.sales_by_month AS
SELECT date_trunc('month', created_at)::date AS month, count(*) AS orders, sum(total_cents) AS total_cents
FROM orders GROUP BY 1 ORDER BY 1;

-- lesson 12's layout.sql
CREATE ROLE shop_owner NOLOGIN;
ALTER DATABASE shop OWNER TO shop_owner;
ALTER TABLE customers OWNER TO shop_owner;
ALTER TABLE orders OWNER TO shop_owner;
ALTER SCHEMA reports OWNER TO shop_owner;
ALTER VIEW reports.sales_by_month OWNER TO shop_owner;
REVOKE CONNECT ON DATABASE shop FROM PUBLIC;
GRANT CONNECT ON DATABASE shop TO app, reporting;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;
GRANT SELECT ON orders TO reporting;
GRANT SELECT (id, name, country, created_at) ON customers TO reporting;
GRANT USAGE ON SCHEMA reports TO reporting;
GRANT SELECT ON reports.sales_by_month TO reporting;
```

Then give the two login roles their passwords with `\password bruno` and `\password app`, typing
`bruno-lab-only` and `app-lab-only`, and write `~/.pgpass` with an editor and `chmod 600` it:

```conf
# ~/.pgpass: hostname:port:database:username:password
localhost:5432:*:bruno:bruno-lab-only
localhost:5432:*:app:app-lab-only
```

Lesson 11 explains the passwords and the file; lesson 12 explains every line of the SQL. The state
to compare with:

```
shop=# \dt
            List of relations
 Schema |   Name    | Type  |   Owner    
--------+-----------+-------+------------
 public | customers | table | shop_owner
 public | orders    | table | shop_owner
(2 rows)

shop=# \dp
                                             Access privileges
 Schema |       Name       |   Type   |       Access privileges       |    Column privileges     | Policies 
--------+------------------+----------+-------------------------------+--------------------------+----------
 public | customers        | table    | shop_owner=arwdDxt/shop_owner+| id:                     +| 
        |                  |          | app=arwd/shop_owner           |   reporting=r/shop_owner+| 
        |                  |          |                               | name:                   +| 
        |                  |          |                               |   reporting=r/shop_owner+| 
        |                  |          |                               | country:                +| 
        |                  |          |                               |   reporting=r/shop_owner+| 
        |                  |          |                               | created_at:             +| 
        |                  |          |                               |   reporting=r/shop_owner | 
 public | customers_id_seq | sequence |                               |                          | 
 public | orders           | table    | shop_owner=arwdDxt/shop_owner+|                          | 
        |                  |          | app=arwd/shop_owner          +|                          | 
        |                  |          | reporting=r/shop_owner        |                          | 
 public | orders_id_seq    | sequence |                               |                          | 
(4 rows)
```

As in lesson 12, a test of another role logs in as that role, with `psql -h localhost -U bruno
shop` or `-U app`, and migrations run as `shop_owner` through `SET ROLE` from `ana`'s session.
