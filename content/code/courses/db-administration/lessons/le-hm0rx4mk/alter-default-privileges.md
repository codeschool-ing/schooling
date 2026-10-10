---
title: ALTER DEFAULT PRIVILEGES, and whose tables it means
version: 1
---

`ALTER DEFAULT PRIVILEGES` stores grants that the server **adds to an object at the moment it is
created**. It is written like a `GRANT`, with a plural object type where the object name would be,
and two clauses that decide which future objects it applies to:

- `FOR ROLE shop_owner` — objects that role creates. Leave it out and it means the role running the
  statement.
- `IN SCHEMA public` — objects created in that schema. Leave it out and it means every schema in
  the current database.

Set the two that lesson 12's layout implies:

```
shop=# ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA public
shop-#     GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app;
ALTER DEFAULT PRIVILEGES

shop=# ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner IN SCHEMA public
shop-#     GRANT SELECT ON TABLES TO reporting;
ALTER DEFAULT PRIVILEGES

shop=# \dp refunds
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | refunds | table |                   |                   | 
(1 row)
```

`refunds` is unchanged: the defaults apply to what is created from now on. Give it its grants by
hand, once:

```
shop=# GRANT SELECT, INSERT, UPDATE, DELETE ON refunds TO app;
GRANT

shop=# GRANT SELECT ON refunds TO reporting;
GRANT
```

And create the next table the way a migration would:

```
shop=# SET ROLE shop_owner;
SET

shop=> CREATE TABLE shipments (
shop(>     id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
shop(>     order_id   bigint NOT NULL REFERENCES orders (id),
shop(>     shipped_at timestamptz NOT NULL DEFAULT now()
shop(> );
CREATE TABLE

shop=> RESET ROLE;
RESET

shop=# \dp shipments
                                     Access privileges
 Schema |   Name    | Type  |       Access privileges       | Column privileges | Policies 
--------+-----------+-------+-------------------------------+-------------------+----------
 public | shipments | table | reporting=r/shop_owner       +|                   | 
        |           |       | app=arwd/shop_owner          +|                   | 
        |           |       | shop_owner=arwdDxt/shop_owner |                   | 
(1 row)
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM shipments;
 count 
-------
     0
(1 row)
```

`shipments` arrived with both grants. Nobody typed a `GRANT` for it, `bruno` can read it, and the
grantor is recorded as `shop_owner`, the owner, as with any grant.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A timeline of five events. First, GRANT ON ALL TABLES runs once and covers the tables that exist, customers and orders. Then shop_owner creates refunds, which gets no grant. Then ALTER DEFAULT PRIVILEGES is run for every table shop_owner creates. Then shop_owner creates shipments, which is granted automatically. Last, ana creates coupons, which gets no grant, because ana is not shop_owner.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><line x1=\"20\" y1=\"104\" x2=\"700\" y2=\"104\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"700\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><text x=\"80\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GRANT ... ON ALL</text><text x=\"80\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TABLES</text><line x1=\"80\" y1=\"72\" x2=\"80\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"80\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"215\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop_owner creates</text><text x=\"215\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refunds</text><line x1=\"215\" y1=\"72\" x2=\"215\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"215\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"350\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ALTER DEFAULT</text><text x=\"350\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">PRIVILEGES</text><line x1=\"350\" y1=\"72\" x2=\"350\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"350\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"485\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shop_owner creates</text><text x=\"485\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shipments</text><line x1=\"485\" y1=\"72\" x2=\"485\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"485\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"620\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana creates</text><text x=\"620\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">coupons</text><line x1=\"620\" y1=\"72\" x2=\"620\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"620\" cy=\"104\" r=\"4\" fill=\"var(--paper)\"></circle><rect x=\"30\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">customers</text><rect x=\"30\" y=\"156\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><rect x=\"165\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">refunds</text><rect x=\"435\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shipments</text><rect x=\"570\" y=\"122\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"620\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">coupons</text><text x=\"80\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">granted</text><text x=\"215\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no grant</text><text x=\"350\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">for every table</text><text x=\"350\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shop_owner creates</text><text x=\"485\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">granted</text><text x=\"620\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no grant: not shop_owner</text></svg>", "caption": "A GRANT reaches the tables that exist when it runs. A default privilege reaches the tables one named role creates afterwards, and nothing else."}
```

## The creator trap

Look at the first clause again: `FOR ROLE shop_owner`. **A default privilege belongs to the role
that creates the object, not to the schema it lands in**, and that is the mistake this feature is
known for. An administrator in a hurry creates a table as herself:

```
shop=# CREATE TABLE coupons (code text PRIMARY KEY, percent integer NOT NULL);
CREATE TABLE

shop=# \dt coupons
        List of relations
 Schema |  Name   | Type  | Owner 
--------+---------+-------+-------
 public | coupons | table | ana
(1 row)

shop=# \dp coupons
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | coupons | table |                   |                   | 
(1 row)

shop=# ALTER TABLE coupons OWNER TO shop_owner;
ALTER TABLE

shop=# \dp coupons
                              Access privileges
 Schema |  Name   | Type  | Access privileges | Column privileges | Policies 
--------+---------+-------+-------------------+-------------------+----------
 public | coupons | table |                   |                   | 
(1 row)
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT count(*) FROM coupons;
ERROR:  permission denied for table coupons
```

`coupons` was created by `ana`, so `shop_owner`'s defaults never looked at it. Changing the owner
afterwards did not help: **`ALTER ... OWNER TO` moves ownership and applies no default
privileges**, because those are applied once, at creation, and the table had already been created.
`bruno` is refused, and the access list is empty under either owner.

The repair is to give it the grants by hand, or, while it is still empty, to create it again as the
right role:

```
shop=# DROP TABLE coupons;
DROP TABLE

shop=# SET ROLE shop_owner;
SET

shop=> CREATE TABLE coupons (code text PRIMARY KEY, percent integer NOT NULL);
CREATE TABLE

shop=> RESET ROLE;
RESET

shop=# \dp coupons
                                    Access privileges
 Schema |  Name   | Type  |       Access privileges       | Column privileges | Policies 
--------+---------+-------+-------------------------------+-------------------+----------
 public | coupons | table | reporting=r/shop_owner       +|                   | 
        |         |       | app=arwd/shop_owner          +|                   | 
        |         |       | shop_owner=arwdDxt/shop_owner |                   | 
(1 row)
```

The same trap catches teams that run `ALTER DEFAULT PRIVILEGES` without `FOR ROLE`. The
administrator runs it as herself, it records defaults for the administrator's own tables, and the
deployment tool, logging in as its own role, creates tables that none of it applies to. **The role
named in `FOR ROLE` has to be the role that runs the migrations**, and that is the strongest reason
for every migration to run as one owner role rather than as whoever happens to deploy.

## What else it covers

The plural object types are `TABLES` (which includes views), `SEQUENCES`, `FUNCTIONS` (which
includes procedures), `TYPES` and `SCHEMAS`. A table with a `serial` column needs `GRANT USAGE ON
SEQUENCES` beside the table grant; identity columns, as lesson 12 showed, do not. A default
privilege is stored in one database and applies only there, like every other grant.
