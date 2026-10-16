---
title: Reading the defaults
version: 1
---

Default privileges are invisible in `\dp`, which shows what objects have, not what they will get.
psql lists them with **`\ddp`**:

```
shop=# \ddp
              Default access privileges
   Owner    | Schema | Type  |   Access privileges    
------------+--------+-------+------------------------
 shop_owner | public | table | reporting=r/shop_owner+
            |        |       | app=arwd/shop_owner
(1 row)
```

One row per combination of creating role, schema and object type. The access list reads like any
other, with the creating role as grantor: tables `shop_owner` creates in `public` will be given
`r` to `reporting` and `arwd` to `app`. An empty `Schema` column means the row applies in every
schema.

## The defaults nobody wrote

`\ddp` only lists defaults somebody changed. **The built-in ones are not rows, and so they are
not shown**: a new table gives nothing to anybody but its owner, and a new function gives
`EXECUTE` to `PUBLIC`, as lesson 12's table of what `PUBLIC` holds said. The second is a default
worth changing in a database where functions can do things a caller should not, and changing it
makes it appear:

```
shop=# ALTER DEFAULT PRIVILEGES FOR ROLE shop_owner REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES

shop=# \ddp
                Default access privileges
   Owner    | Schema |   Type   |    Access privileges    
------------+--------+----------+-------------------------
 shop_owner | public | table    | reporting=r/shop_owner +
            |        |          | app=arwd/shop_owner
 shop_owner |        | function | shop_owner=X/shop_owner
(2 rows)
```

The new row has no schema, so it applies to functions `shop_owner` creates anywhere in `shop`. Its
access list is `shop_owner=X/shop_owner`, `X` being execute: the owner keeps the right and **the
entry for `PUBLIC` that was there invisibly is gone**. Every function `shop_owner` creates from now
on is callable by its owner alone until somebody grants it.

Two more things about reading them. A default set `IN SCHEMA` can only add to what applies
everywhere; it cannot take away a grant that a schema-less default gives. And `\ddp` shows the
defaults of the database you are connected to, so a cluster with ten databases has ten lists to
read.

## What the catalogue holds

`\ddp` reads the catalogue table `pg_default_acl`, which has one row per line of that listing, with the creating role,
the schema and the object type as codes. A script that checks a database against its intended
layout reads that table, as it would read `has_table_privilege` for the grants objects already
have. Between the two, every permission a role holds today or will hold tomorrow is a query away.
