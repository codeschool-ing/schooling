---
title: Ownership, and dropping a role that owns things
version: 1
---

Every object has exactly one owner, and **a role cannot be dropped while it owns anything or holds
any privilege**. The server refuses, rather than leave tables owned by nobody or access lists
naming a role that no longer exists. That refusal is the reason removing somebody who has left is
a procedure and not one statement.

An intern was given a corner of the `reports` schema, made a table in it, shared it with
`reporting`, and also owns a table in the database `ana`:

```
shop=# CREATE ROLE intern LOGIN;
CREATE ROLE

shop=# GRANT USAGE, CREATE ON SCHEMA reports TO intern;
GRANT

shop=# SET ROLE intern;
SET

shop=> CREATE TABLE reports.ideas (body text);
CREATE TABLE

shop=> GRANT SELECT ON reports.ideas TO reporting;
GRANT

shop=> RESET ROLE;
RESET

shop=# \c ana
You are now connected to database "ana" as user "ana".

ana=# CREATE TABLE notes (body text);
CREATE TABLE

ana=# ALTER TABLE notes OWNER TO intern;
ALTER TABLE

ana=# \c shop
You are now connected to database "shop" as user "ana".

shop=# DROP ROLE intern;
ERROR:  role "intern" cannot be dropped because some objects depend on it
DETAIL:  privileges for schema reports
owner of table reports.ideas
1 object in database ana
```

The `DETAIL` is an inventory: a privilege on the schema, a table he owns, and **`1 object in
database ana`**. Ownership in other databases is only counted, never named, because a session
can see the catalogue of the database it is connected to and no other.

## REASSIGN OWNED, then DROP OWNED

Two statements clear a role, and the order matters:

- `REASSIGN OWNED BY intern TO shop_owner` gives everything the intern owns to another role.
  The table survives, with a new owner.
- `DROP OWNED BY intern` drops whatever he still owns and revokes every privilege granted to
  him, along with his default privileges.

Run the second first and the intern's table is dropped instead of kept. Both act on **the current
database only**, which the first attempt shows:

```
shop=# REASSIGN OWNED BY intern TO shop_owner;
REASSIGN OWNED

shop=# DROP OWNED BY intern;
DROP OWNED

shop=# DROP ROLE intern;
ERROR:  role "intern" cannot be dropped because some objects depend on it
DETAIL:  1 object in database ana

shop=# \c ana
You are now connected to database "ana" as user "ana".

ana=# REASSIGN OWNED BY intern TO ana;
REASSIGN OWNED

ana=# DROP OWNED BY intern;
DROP OWNED

ana=# DROP ROLE intern;
DROP ROLE
```

`DROP ROLE` still found the object in `ana`. Connected there, the same two statements cleared it,
handing that table to `ana`, and the role could go. On a cluster with many databases this is a loop
over all of them, and the `DETAIL` of the failed `DROP ROLE` is the list of which ones to visit.

The table the intern made is now `shop_owner`'s, and the grant he made on it survived, rewritten
with the new owner as grantor:

```
shop=# \dp reports.ideas
                                   Access privileges
 Schema  | Name  | Type  |       Access privileges       | Column privileges | Policies 
---------+-------+-------+-------------------------------+-------------------+----------
 reports | ideas | table | shop_owner=arwdDxt/shop_owner+|                   | 
         |       |       | reporting=r/shop_owner        |                   | 
(1 row)
```

`reporting` still reads it. If the intern's table should have died with him, `DROP OWNED` without
the `REASSIGN` is the statement; that is a decision about data and deserves a second look before
it is run.

## A failed DROP ROLE as an inventory

Because the refusal lists everything that depends on a role, it is also the quickest answer to
"what does this role have here?". The statement changes nothing when it fails:

```
shop=# DROP ROLE reporting;
ERROR:  role "reporting" cannot be dropped because some objects depend on it
DETAIL:  privileges for database shop
privileges for column id of table customers
privileges for column name of table customers
privileges for column country of table customers
privileges for column created_at of table customers
privileges for table orders
privileges for schema reports
privileges for view reports.sales_by_month
privileges for table refunds
privileges for default privileges on new relations belonging to role shop_owner in schema public
privileges for table shipments
privileges for table coupons
privileges for table reports.ideas
```

Every door lesson 12 opened for `reporting` is there: the database, four columns of `customers`,
the tables and the view, the schema, the default privilege from this lesson, and the grants that
default made on `shipments` and `coupons`. Do not do this on a role that might have nothing left,
because then the statement succeeds.
