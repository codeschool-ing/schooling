---
title: Nobody, until a grant says otherwise
version: 1
---

Bruno can log in. The first gate has said yes. What can he do?

```
ana@lab:~/gov$ psql -c "\l ipe"
                                               List of databases
 Name |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules | Access privileges 
------+----------+----------+-----------------+---------+---------+------------+-----------+-------------------
 ipe  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | 
(1 row)

ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "SELECT count(*) FROM sales.customers"
ERROR:  permission denied for schema sales
LINE 1: SELECT count(*) FROM sales.customers
                             ^
ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "\dn"
       List of schemas
  Name   |       Owner       
---------+-------------------
 health  | ipe_owner
 public  | pg_database_owner
 sales   | ipe_owner
 support | ipe_owner
(4 rows)
```

**He can read nothing, and he can see the shape of everything.** The tables are refused at the
schema, because nobody has granted him `USAGE` on `sales`; that is the second gate, and it held.
But he can list the schemas, and every other catalogue view: the names of the tables, their
columns, the names of the other roles. The catalogue is readable by every role that can connect,
and that is by design — a client needs it to work at all. It is also why a table name like
`customers_with_hiv_status` is a leak in itself, whatever its grants say.

## The role everybody is in

The `\l` above shows an empty **Access privileges** column for `ipe`. Empty does not mean
nothing: it means **the defaults**, and the default for a database is that the pseudo-role
`PUBLIC` — every role, including ones created next year — may connect to it and create temporary
tables in it.

**A default that grants is a policy nobody wrote.** It means every new role can open a session on
`ipe` the moment it has a password, whether or not anybody decided it should. Ana turns the
default around: nobody connects unless named.

```sql
-- Who may open a session on `ipe` at all: nobody, until a grant says so.
REVOKE CONNECT, TEMPORARY ON DATABASE ipe FROM PUBLIC;
GRANT CONNECT ON DATABASE ipe TO bruno, carla, davi, site_app, etl_loader;
```

```
ana@lab:~/gov$ sudo -u postgres psql -d ipe < connect.sql
REVOKE
GRANT
ana@lab:~/gov$ psql -c "\l ipe"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  permission denied for database "ipe"
DETAIL:  User does not have CONNECT privilege.
ana@lab:~/gov$ sudo -u postgres psql -c "GRANT CONNECT ON DATABASE ipe TO ana"
GRANT
ana@lab:~/gov$ psql -c "\l ipe"
                                                 List of databases
 Name |  Owner   | Encoding | Locale Provider | Collate |  Ctype  | ICU Locale | ICU Rules |   Access privileges   
------+----------+----------+-----------------+---------+---------+------------+-----------+-----------------------
 ipe  | postgres | UTF8     | libc            | C.UTF-8 | C.UTF-8 |            |           | postgres=CTc/postgres+
      |          |          |                 |         |         |            |           | bruno=c/postgres     +
      |          |          |                 |         |         |            |           | carla=c/postgres     +
      |          |          |                 |         |         |            |           | davi=c/postgres      +
      |          |          |                 |         |         |            |           | site_app=c/postgres  +
      |          |          |                 |         |         |            |           | etl_loader=c/postgres+
      |          |          |                 |         |         |            |           | ana=c/postgres
(1 row)
```

The first `\l` is Ana locking herself out. She was relying on `PUBLIC` like everybody else, and
the list of names she granted to did not include her own — exactly the mistake the default
hides. **The error says what is missing**, `User does not have CONNECT privilege`, and the
superuser puts it right with one grant. The second `\l` is the policy written down: one line per
role allowed in, each granted by `postgres`, and nothing for `PUBLIC`.

Lia, whose password expired, is not on the list. If somebody extended her password by mistake,
she still could not open a session on `ipe`. **Two controls that fail independently are what
"defence in depth" means at the size of one database**: an expiry date that nobody has to
remember, and a grant that nobody made.

## Where this leaves the lab

Every person and program has a login of its own, every login has a method that proves it, the
door logs who came through, and being let in gives nobody any data at all. That last part is the
starting point of lesson 2, which decides — table by table, column by column and row by row —
what each of them may read.
