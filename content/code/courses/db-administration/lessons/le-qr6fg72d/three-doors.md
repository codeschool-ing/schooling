---
title: Three doors on the way to a row
version: 1
---

A role that wants to read a table has to get through **three doors, in order**: `CONNECT` on the
database, `USAGE` on the schema the table is in, and the privilege on the table itself. Each door
is checked separately, each refusal has its own sentence, and a key to the inner door is worth
nothing while an outer one is shut. When an application says "permission denied", the words after
those two tell you which door it hit.

The tempting picture is that a `GRANT SELECT` on a table is access to the table. It is access to
the last door.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three nested boxes: the database shop contains the schema reports, which contains the view sales_by_month. An arrow for a session as bruno crosses three boundaries on its way to the view, and each boundary is a door marked with the privilege it asks for: CONNECT on the database, checked at login; USAGE on the schema, checked when a name is looked up in it; SELECT on the view, checked per object.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"140\" y=\"16\" width=\"566\" height=\"188\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"154\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">database</text><text x=\"212\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop</text><rect x=\"300\" y=\"48\" width=\"396\" height=\"144\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">schema</text><text x=\"364\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">reports</text><rect x=\"460\" y=\"80\" width=\"226\" height=\"100\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"474\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">view</text><text x=\"474\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sales_by_month</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a session as</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">bruno</text><line x1=\"70\" y1=\"160\" x2=\"600\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#arr)\"></line><rect x=\"106\" y=\"148\" width=\"68\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CONNECT</text><rect x=\"266\" y=\"148\" width=\"68\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">USAGE</text><rect x=\"426\" y=\"148\" width=\"68\" height=\"24\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">SELECT</text><text x=\"220\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked at login</text><text x=\"380\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked by name</text><text x=\"573\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checked per object</text></svg>", "caption": "Three doors, each with its own privilege and its own refusal. Holding the innermost one opens nothing if an outer one is shut."}
```

## The database: CONNECT

A brand-new role can connect to every database in the cluster, because **PostgreSQL gives `CONNECT`
on every database to `PUBLIC`**, the pseudo-role that means everybody. `bruno` has been granted
nothing, and logs in to `shop` anyway. Take the privilege away from `PUBLIC` and the door shuts:

```
ana@db:~$ psql -h localhost -U bruno shop -c "SELECT current_user;"
 current_user 
--------------
 bruno
(1 row)

shop=# REVOKE CONNECT ON DATABASE shop FROM PUBLIC;
REVOKE

shop=# \l shop
                                             List of databases
 Name | Owner | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules | Access privileges 
------+-------+----------+-----------------+---------+---------+------------+-----------+-------------------
 shop | ana   | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =T/ana           +
      |       |          |                 |         |         |            |           | ana=CTc/ana
(1 row)
ana@db:~$ psql -h localhost -U bruno shop -c "SELECT current_user;"
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  permission denied for database "shop"
DETAIL:  User does not have CONNECT privilege.
shop=# GRANT CONNECT ON DATABASE shop TO reporting, app;
GRANT
```

`\l shop` printed the database's access list for the first time, because a list that was never
changed is stored as empty and means "the defaults". Now it is written out, one entry per line in
the form `grantee=privileges/grantor`. **An empty grantee is `PUBLIC`**: `=T/ana` says everybody
keeps `T`, the right to create temporary tables, and lost `c`, connect. `ana=CTc/ana` is the owner's
full set, `C` being the right to create schemas. Lesson 13 uses the same letters for tables.

The refusal came from the server at login, before any SQL ran, with a `DETAIL` naming the missing
privilege. `GRANT CONNECT ... TO reporting` let `bruno` back in through his group, and `app` got
the same, because it will need it.

## The schema: USAGE

A schema is a namespace inside a database, and a role needs **`USAGE` on a schema to look up any
name in it**. Make one for reports, put a view in it that sums the orders by month, and grant
`reporting` the right to read the view, and nothing else:

```
shop=# CREATE SCHEMA reports;
CREATE SCHEMA

shop=# CREATE VIEW reports.sales_by_month AS
shop-# SELECT date_trunc('month', created_at)::date AS month, count(*) AS orders, sum(total_cents) AS total_cents
shop-# FROM orders GROUP BY 1 ORDER BY 1;
CREATE VIEW

shop=# GRANT SELECT ON reports.sales_by_month TO reporting;
GRANT
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT * FROM reports.sales_by_month;
ERROR:  permission denied for schema reports
LINE 1: SELECT * FROM reports.sales_by_month;
                      ^

shop=> SELECT count(*) FROM customers;
ERROR:  permission denied for table customers
```

Two queries, two different doors. The view is refused at the schema, `permission denied for schema
reports`, even though the grant on the view itself exists. `customers` is refused at the table,
`permission denied for table customers`: the schema door was open, because `public` gives `USAGE`
to everybody, and the table door was not. Open the schema:

```
shop=# GRANT USAGE ON SCHEMA reports TO reporting;
GRANT
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT * FROM reports.sales_by_month;
   month    | orders | total_cents 
------------+--------+-------------
 2026-01-01 | 129176 |  3293617315
 2026-02-01 | 116676 |  2975134074
 2026-03-01 | 129177 |  3293611206
 2026-04-01 | 125010 |  3187726565
 2026-05-01 | 129177 |  3294763695
 2026-06-01 | 124990 |  3186856365
 2026-07-01 | 129146 |  3293209392
 2026-08-01 | 116648 |  2974581388
(8 rows)
```

**`bruno` now reads a sum over a million orders without any privilege on `orders`.** A view runs
its query with the privileges of the view's owner, here `ana`, so the view is a door of its own: it
lets through exactly the columns and rows its query produces. That is the usual way to give a narrow
window onto a wide table. A view created `WITH (security_invoker = true)`, possible since version 15,
checks the querying role's privileges on the tables underneath instead.

## Asking without logging in

Logging in as the role is the honest test, and it needs the role's password. The server can also
answer the question directly, for any role, from a superuser's session:

```
shop=# SELECT has_database_privilege('bruno', 'shop', 'CONNECT') AS connect, has_schema_privilege('bruno', 'reports', 'USAGE') AS usage, has_table_privilege('bruno', 'customers', 'SELECT') AS select;
 connect | usage | select 
---------+-------+--------
 t       | t     | f
(1 row)
```

`has_database_privilege`, `has_schema_privilege` and `has_table_privilege` follow membership the
way a real session would, so `bruno` is reported as able to connect through `reporting`. They are
what a script that audits grants should call, rather than reading access lists itself.
