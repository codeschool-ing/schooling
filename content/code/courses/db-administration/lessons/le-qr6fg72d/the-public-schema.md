---
title: The public schema, and what PUBLIC is given
version: 1
---

Every database is created with a schema called `public`, and every table in `shop` is in it. **What
`PUBLIC` may do in that schema changed in PostgreSQL 15**, and the change is one of the few in
recent years that made a default safer by breaking scripts that relied on the old one.

## What version 16 gives

```
shop=# \dn+ public
                                       List of schemas
  Name  |       Owner       |           Access privileges            |      Description       
--------+-------------------+----------------------------------------+------------------------
 public | pg_database_owner | pg_database_owner=UC/pg_database_owner+| standard public schema
        |                   | =U/pg_database_owner                   | 
(1 row)
ana@db:~$ psql -h localhost -U bruno shop
shop=> CREATE TABLE notes (body text);
ERROR:  permission denied for schema public
LINE 1: CREATE TABLE notes (body text);
                     ^

shop=> CREATE TEMP TABLE notes (body text);
CREATE TABLE
```

Two entries. The owner of the schema is **`pg_database_owner`**, a predefined role whose only member
is, at any moment, whoever owns the current database; here that is `ana`, and she gets `U`, usage,
and `C`, create. Everybody else, the empty grantee, gets `U` alone. So any role that can connect may
use the tables in `public` that it holds privileges on, and **may not create anything there**.
`bruno`'s `CREATE TABLE` was refused at the schema.

His temporary table worked, because temporary tables live in a schema of their own for each
session, and `PUBLIC` still holds `T` on the database, as `\l shop` showed in the section before.
A temporary table disappears with the session and touches nobody else's data. If even that is too
much, `REVOKE TEMPORARY ON DATABASE shop FROM PUBLIC` removes it.

## What versions before 15 gave

**Up to version 14, `PUBLIC` had `CREATE` on `public`, and the schema was owned by the bootstrap
superuser**, so the access list read `=UC/postgres`. Every role that could connect could create
tables, views and functions in the schema every other role searches first. That second half is
the dangerous one: a function created in `public` with the name of one an administrator calls,
and argument types that fit the call more closely, is chosen instead of the real one and runs with
the administrator's rights. The project published it as a security problem in 2018
(CVE-2018-1058) and spent four years recommending the `REVOKE` before making it the default.

**The new default only applies to databases created by version 15 or later.** A database that came
from an older server by `pg_upgrade`, or by a dump and restore of its schema, keeps the access list
it had, `=UC/postgres` included. After any upgrade from 14 or earlier, look at `\dn+ public` in
every database and, where `C` is still beside the empty grantee, run:

```sql
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
```

Lesson 20 performs a major upgrade and lists this among the checks that follow one.

## The other things PUBLIC holds

`PUBLIC` is given a short list by default, and it is worth knowing by heart, because each item is
a door already open when a role is created:

| object | what `PUBLIC` gets | what a careful database does |
|---|---|---|
| a database | `CONNECT`, `TEMPORARY` | revokes `CONNECT` and grants it per role, as the section before did |
| the `public` schema | `USAGE` (and `CREATE` before 15) | revokes `CREATE` where an old server left it |
| a function or procedure | `EXECUTE` | revokes it on functions that should not be callable by everybody |
| a language, a type | `USAGE` | leaves it alone |

**A table, a view, a sequence and a schema you create yourself give `PUBLIC` nothing.** Everything
on them has to be granted, which is what the rest of this lesson does.
