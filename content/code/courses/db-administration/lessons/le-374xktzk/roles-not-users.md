---
title: A role, not a user
version: 1
---

PostgreSQL has **one kind of account, and it calls it a role**. A role that may log in is what
other systems call a user; a role that may not is what they call a group; and the same role can be
both at once. Roles live inside the cluster and have nothing to do with the accounts in
`/etc/passwd`, even when the names happen to match.

The wrong picture is the one lesson 3 left behind: your operating-system user is `ana`, your role
is `ana`, so the two must be one thing. They are two things with the same name, and the server
only joins them at the door, when somebody connects. The rest of this lesson keeps them apart on
purpose.

## Two lists that share nothing

The machine has no user called `bruno`, and the cluster has two roles of its own besides the
predefined `pg_` ones:

```
ana@db:~$ id bruno
id: 'bruno': no such user
shop=# SELECT rolname FROM pg_roles WHERE rolname !~ '^pg_';
 rolname  
----------
 postgres
 ana
(2 rows)

shop=# CREATE ROLE reporting;
CREATE ROLE

shop=# CREATE USER bruno;
CREATE ROLE

shop=# CREATE USER app;
CREATE ROLE

shop=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ana       | Superuser, Create role, Create DB
 app       | 
 bruno     | 
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
 reporting | Cannot login
```

`CREATE USER` answered `CREATE ROLE`, because that is all it is: **`CREATE USER` is `CREATE ROLE`
with `LOGIN` switched on**. The only difference between `reporting` and `bruno` in that listing is
the `Cannot login` beside the first. `CREATE GROUP` exists too, as a third spelling of `CREATE ROLE`
kept for old scripts. Use `CREATE ROLE` and say `LOGIN` when you mean it, so the statement says
what it does.

The three roles have jobs for the next three lessons. **`reporting` is a group** that will be given
read access; **`bruno` is a person**, an analyst who will be put in that group; **`app` is the
application**, which connects with a password and writes orders. None of them can do anything yet.

`bruno` got no account on the machine, and needs none. He will connect to the database from
wherever he works, and the server will never ask the operating system whether he exists.

## A role belongs to the cluster, a table to one database

A table lives in one database. A role does not: it is stored in `pg_authid`, one of the few
catalogue tables **shared by every database in the cluster**, and so is the list of databases
itself.

```
shop=# SELECT relname, relisshared FROM pg_class WHERE relname IN ('pg_authid', 'pg_database', 'pg_class', 'customers');
   relname   | relisshared 
-------------+-------------
 customers   | f
 pg_authid   | t
 pg_class    | f
 pg_database | t
(4 rows)

shop=# \c ana
You are now connected to database "ana" as user "ana".

ana=# SELECT rolname FROM pg_roles WHERE rolname = 'bruno';
 rolname 
---------
 bruno
(1 row)
```

`bruno` was created while connected to `shop` and is just as present in `ana`. What he may DO in
each database is a separate matter, decided by grants that live inside each one; lesson 12 is about
those. `pg_roles` is the readable view over `pg_authid`, with the password column blanked out, and
it is the one to query by habit.

## The same idea in the other three engines

Each of the engines lesson 2 introduced draws this line somewhere else, and the vocabulary trips
people moving between them:

| engine | an account is | belongs to |
|---|---|---|
| PostgreSQL | a role, `LOGIN` or not | the cluster |
| MySQL | `'user'@'host'`: the same name from two hosts is two accounts | the server |
| SQL Server | a login at the server, mapped to a user in each database | both, in two steps |
| Oracle | a user, which is also a schema holding that user's objects | the database |

SQL Server's two steps are the closest to PostgreSQL's split between a role and its grants, and
Oracle's is the furthest: there, creating a user creates a place for tables, and here a role owns
nothing until it creates something.
