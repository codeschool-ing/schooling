---
title: A least-privilege layout for shop
version: 1
---

The sections so far opened one door at a time. A real database is given its doors all at once, by
a file somebody reads, and **three roles cover most applications**:

| role | logs in | what it may do |
|---|---|---|
| `shop_owner` | never | owns every object; migrations run as it |
| `app` | yes, the application | read and write rows; never change a table's shape |
| `reporting` | no, a group; `bruno` logs in | read, minus personal data |

The idea that does the work is the first row. **Whoever owns a table can do anything to it**: alter
it, drop it, grant on it, skip its row-level security. Ownership cannot be limited by a grant. So
the owner is a role that nobody logs in as, and the application's role owns nothing. A bug or an
injected statement in the application can then lose rows, which a backup brings back. It cannot
drop a table or change who may read it.

Write the file with an editor as `layout.sql` in your home directory:

```schooling-example
{"language": "sql", "file": "layout.sql", "parts": [{"code": "-- layout.sql: who owns shop, who writes to it, who reads it\nCREATE ROLE shop_owner NOLOGIN;", "note": "The owner is a role nobody logs in as. Migrations run as it, through `SET ROLE shop_owner` from an administrator's session, so no password exists that could drop a table."}, {"code": "ALTER DATABASE shop OWNER TO shop_owner;\nALTER TABLE customers OWNER TO shop_owner;\nALTER TABLE orders OWNER TO shop_owner;\nALTER SCHEMA reports OWNER TO shop_owner;\nALTER VIEW reports.sales_by_month OWNER TO shop_owner;", "note": "Owning the database makes `shop_owner` the `pg_database_owner` of `shop`, so it may create tables in `public`. An identity column's sequence moves with its table."}, {"code": "REVOKE CONNECT ON DATABASE shop FROM PUBLIC;\nGRANT CONNECT ON DATABASE shop TO app, reporting;", "note": "The first door, closed to everybody and opened to the two roles that need it. Both lines were run earlier in the lesson; a grant that already exists is not an error, so the file can run again."}, {"code": "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app;", "note": "The application reads and writes rows. It gets no `TRUNCATE`, no `REFERENCES`, no `TRIGGER`, and it owns nothing, so it cannot change a table's shape or drop one."}, {"code": "GRANT SELECT ON orders TO reporting;\nGRANT SELECT (id, name, country, created_at) ON customers TO reporting;\nGRANT USAGE ON SCHEMA reports TO reporting;\nGRANT SELECT ON reports.sales_by_month TO reporting;", "note": "Reporting reads every order, every customer column except `email`, and the view. A person's address is the one column an analyst does not need."}]}
```

Run it as `ana`:

```
ana@db:~$ psql shop -f layout.sql
CREATE ROLE
ALTER DATABASE
ALTER TABLE
ALTER TABLE
ALTER SCHEMA
ALTER VIEW
REVOKE
GRANT
GRANT
GRANT
GRANT
GRANT
GRANT
shop=# \l shop
                                                    List of databases
 Name |   Owner    | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |     Access privileges     
------+------------+----------+-----------------+---------+---------+------------+-----------+---------------------------
 shop | shop_owner | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | =T/shop_owner            +
      |            |          |                 |         |         |            |           | shop_owner=CTc/shop_owner+
      |            |          |                 |         |         |            |           | reporting=c/shop_owner   +
      |            |          |                 |         |         |            |           | app=c/shop_owner
(1 row)

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

shop=# \dp reports.*
                                       Access privileges
 Schema  |      Name      | Type |       Access privileges       | Column privileges | Policies 
---------+----------------+------+-------------------------------+-------------------+----------
 reports | sales_by_month | view | shop_owner=arwdDxt/shop_owner+|                   | 
         |                |      | reporting=r/shop_owner        |                   | 
(1 row)
```

The database's owner is `shop_owner` now, and the grants made earlier by `ana` have been rewritten
with the new owner as grantor, because **a grant on an object is always recorded as made by its
owner** when a superuser makes it. `\dp` reads the same way it did for the database: `app=arwd`
is `a`ppend (insert), `r`ead (select), `w`rite (update) and `d`elete; the owner's `arwdDxt` adds
`D` for truncate, `x` for references and `t` for trigger. The two sequences show no entry, and the
next test shows why that is right.

## Testing the layout

Log in as each role and try what it should and should not do:

```
ana@db:~$ psql -h localhost -U app shop
shop=> BEGIN;
BEGIN

shop=*> INSERT INTO orders (customer_id, status, total_cents, created_at) VALUES (1, 'paid', 990, now());
INSERT 0 1

shop=*> ROLLBACK;
ROLLBACK

shop=> DROP TABLE orders;
ERROR:  must be owner of table orders

shop=> CREATE TABLE notes (body text);
ERROR:  permission denied for schema public
LINE 1: CREATE TABLE notes (body text);
                     ^
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT email FROM customers LIMIT 1;
ERROR:  permission denied for table customers

shop=> SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)
```

`app` inserted an order without any grant on `orders_id_seq`. **An identity column takes its next
value without checking privileges on its sequence**; a column declared `serial`, the older way,
would have needed `GRANT USAGE ON SEQUENCE orders_id_seq TO app` as well. It could not drop the
table, because only the owner can, and could not create one, because `public` gives `CREATE` to
the database's owner alone. `bruno` was refused the e-mail addresses and reads every order.

## Working as the owner

Migrations, the scripts that create and change tables, run as `shop_owner`. From an administrator's
session that is one statement:

```sql
SET ROLE shop_owner;
-- CREATE TABLE, ALTER TABLE ...
RESET ROLE;
```

`ana` is a superuser and can `SET ROLE` to anybody. A deployment tool that is not would log in as
its own role, a member of `shop_owner` with `INHERIT FALSE`, and switch only while it migrates;
lesson 11 explained why that option exists. A table created between the two lines belongs to
`shop_owner`, like the rest.

**What it will not have is any grant for `app` or `reporting`.** `GRANT ... ON ALL TABLES IN
SCHEMA` reached the tables that existed when it ran and no others. That is the subject of lesson 13.
