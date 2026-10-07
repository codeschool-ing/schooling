---
title: A privilege is a verb on an object
version: 1
---

Lesson 1 left every role able to connect and none able to read. This lesson fills the gap, and
it starts with what a privilege is: **a verb, on an object, granted to a role.** `SELECT` on a
table, `USAGE` on a schema, `EXECUTE` on a function, `CONNECT` on a database. Nothing is granted
in general; every privilege names the thing it is about.

Ana will be testing as other people all lesson, so she writes down how to reach each of them.
A **service file** saves typing the host, the port, the database and the user every time:

```ini
# One entry per role Ana tests as. `psql service=bruno` reads the host,
# the port, the database and the user from here, and the password from
# ~/.pgpass as before.
[bruno]
host=db.ipe.example
port=5433
dbname=ipe
user=bruno

[carla]
host=db.ipe.example
port=5433
dbname=ipe
user=carla

[site_app]
host=db.ipe.example
port=5433
dbname=ipe
user=site_app
```

The password still comes from `~/.pgpass`. `psql service=bruno` is now the same as the long
command of lesson 1.

## Starting from nothing

```
ana@lab:~/gov$ psql -c "\dp sales.*"
                                Access privileges
 Schema |    Name     | Type  | Access privileges | Column privileges | Policies 
--------+-------------+-------+-------------------+-------------------+----------
 sales  | customers   | table |                   |                   | 
 sales  | order_items | table |                   |                   | 
 sales  | orders      | table |                   |                   | 
 sales  | payments    | table |                   |                   | 
 sales  | products    | table |                   |                   | 
(5 rows)
```

`\dp` lists access privileges. Every table in `sales` shows an empty column, which, as with the
database in lesson 1, means the defaults — and for a table the default is that **only the owner
may do anything**. Nobody else has been given a verb.

Ana's first attempt is the natural one: give Bruno what he asks for.

```sql
SET ROLE ipe_owner;
GRANT USAGE ON SCHEMA sales TO bruno;
GRANT SELECT ON sales.orders TO bruno;
```

```
ana@lab:~/gov$ psql -f first-grant.sql
SET
GRANT
GRANT
ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.orders"
 count 
-------
 36424
(1 row)

ana@lab:~/gov$ psql service=bruno -c "SELECT count(*) FROM sales.order_items"
ERROR:  permission denied for table order_items
ana@lab:~/gov$ psql -c "\dp sales.orders"
                                  Access privileges
 Schema |  Name  | Type  |      Access privileges      | Column privileges | Policies 
--------+--------+-------+-----------------------------+-------------------+----------
 sales  | orders | table | ipe_owner=arwdDxt/ipe_owner+|                   | 
        |        |       | bruno=r/ipe_owner           |                   | 
(1 row)
```

Two grants were needed for one table. **`USAGE` on the schema lets a role look inside it**, and
**`SELECT` on the table lets it read the rows**; either alone is refused. And Bruno got exactly what
was granted: `order_items` is still closed, because nobody named it.

The privileges column now reads `bruno=r/ipe_owner`: *bruno* may *r*ead, granted by *ipe_owner*.
The owner's own line, `arwdDxt`, is every verb a table has:

| letter | privilege | letter | privilege |
|---|---|---|---|
| `a` | INSERT (append) | `D` | TRUNCATE |
| `r` | SELECT (read) | `x` | REFERENCES |
| `w` | UPDATE (write) | `t` | TRIGGER |
| `d` | DELETE | | |

## Only the owner hands out the keys

Ana tries to grant the next table without becoming the owner first:

```
ana@lab:~/gov$ psql -c "GRANT SELECT ON sales.order_items TO bruno"
ERROR:  permission denied for schema sales
ana@lab:~/gov$ psql -c "SELECT tableowner FROM pg_tables WHERE tablename = 'order_items'"
 tableowner 
------------
 ipe_owner
(1 row)
```

She is refused at the schema, before the table is even considered. **Ana herself has no
privileges on Ipê's data.** She can become `ipe_owner` when she chooses to, which is what
`SET ROLE` did in the file above; without it she is a role like any other. That is the
arrangement lesson 1 built on purpose, and here is the first time it shows: the person who
administers access does not, by default, read the data.

Granting person by person works for one analyst and one table. It does not survive a team of
analysts and forty tables, and the next section replaces it.
