---
title: Predefined roles
version: 1
---

Some needs come up on every server: a backup tool that must read everything, a monitoring agent
that must see every session, an on-call engineer who must be able to stop a runaway query. Before
version 10 the usual answer to most of them was `SUPERUSER`. **PostgreSQL now ships roles that
carry one of those powers each**, named with a `pg_` prefix and granted like any group:

```
shop=# SELECT rolname FROM pg_roles WHERE rolname LIKE 'pg\_%' ORDER BY 1;
           rolname           
-----------------------------
 pg_checkpoint
 pg_create_subscription
 pg_database_owner
 pg_execute_server_program
 pg_monitor
 pg_read_all_data
 pg_read_all_settings
 pg_read_all_stats
 pg_read_server_files
 pg_signal_backend
 pg_stat_scan_tables
 pg_use_reserved_connections
 pg_write_all_data
 pg_write_server_files
(14 rows)
```

`\du` hides them; the query above lists the fourteen that version 16 has. The ones an
administrator grants most:

| role | what a member may do |
|---|---|
| `pg_read_all_data` | read every table, view and sequence, in every schema, as if it held `SELECT` and `USAGE` everywhere |
| `pg_write_all_data` | insert, update and delete in every table, the same way |
| `pg_monitor` | see every session's query in `pg_stat_activity`, and read the statistics views and settings a monitoring tool needs |
| `pg_signal_backend` | cancel or terminate the sessions of other roles that are not superusers |
| `pg_checkpoint` | run `CHECKPOINT` |
| `pg_use_reserved_connections` | use the connection slots reserved by `reserved_connections`, new in 16 |
| `pg_read_server_files`, `pg_write_server_files`, `pg_execute_server_program` | read files, write files and run programs on the server as the `postgres` user |

**The last three are a superuser by another name**: whoever can write the server's files can
rewrite its configuration, and whoever can run a program there owns the machine's database account.
Grant them as you would grant `SUPERUSER`, which is to say almost never. `pg_database_owner` from
lesson 12 is in the list too, and is the one role nobody is granted: its member is whoever owns the
current database.

## Reading everything, and the door it does not open

`pg_read_all_data` is the role for a backup tool, an auditor or a data export:

```
shop=# CREATE ROLE auditor LOGIN IN ROLE pg_read_all_data;
CREATE ROLE

shop=# SELECT has_database_privilege('auditor', 'shop', 'CONNECT');
 has_database_privilege 
------------------------
 f
(1 row)

shop=# SET ROLE auditor;
SET

shop=> SELECT email FROM customers ORDER BY id LIMIT 1;
         email         
-----------------------
 customer1@example.com
(1 row)

shop=> SELECT count(*) FROM reports.ideas;
 count 
-------
     0
(1 row)

shop=> INSERT INTO coupons VALUES ('WELCOME', 10);
ERROR:  permission denied for table coupons

shop=> RESET ROLE;
RESET

shop=# DROP ROLE auditor;
DROP ROLE
```

The auditor read `email`, which `reporting` was never given, and a table created by an intern
minutes ago, with no grant on either and no default privilege to thank. It could not write. And
**it could not have logged in at all**: `pg_read_all_data` stands in for table and schema
privileges, not for `CONNECT`, which `shop` gives only to `app` and `reporting`. A role made for
reading has to be given the first door like any other.

Row-level security still filters it unless it also has `BYPASSRLS`, and its reach includes the
tables that will exist next year. That is exactly what a backup needs and too much for an analyst, whose access is the deliberate list lesson 12 built.

## Seeing and stopping other sessions

For the next two, start a slow query as `app` in a second terminal, so there is a session to look
at:

```sh
psql -h localhost -U app shop -c "SELECT pg_sleep(60)"
```

Then, as `bruno`, look for it, once without `pg_monitor` and once with it:

```
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pid, usename, state, query FROM pg_stat_activity WHERE usename = 'app';
 pid | usename | state |          query           
-----+---------+-------+--------------------------
 296 | app     |       | <insufficient privilege>
(1 row)
shop=# GRANT pg_monitor TO bruno;
GRANT ROLE
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pid, usename, state, query FROM pg_stat_activity WHERE usename = 'app';
 pid | usename | state  |        query        
-----+---------+--------+---------------------
 296 | app     | active | SELECT pg_sleep(60)
(1 row)
```

**Without the role, `pg_stat_activity` shows that a session exists and hides what it is doing**: the
process id and the user are there, the state is empty and the query reads `<insufficient
privilege>`. A role always sees its own sessions in full and a superuser sees everything, which is
why a monitoring tool tried out as a superuser and deployed as a smaller role shows a list of
sessions with no queries in it. With `pg_monitor`, `bruno` saw the query.

`pg_signal_backend` is the right to do something about it. Lesson 10 used `pg_terminate_backend`
as a superuser; here is the same call from a role that is not one:

```
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'app';
ERROR:  permission denied to terminate process
DETAIL:  Only roles with privileges of the role whose process is being terminated or with privileges of the "pg_signal_backend" role may terminate this process.
shop=# GRANT pg_signal_backend TO bruno;
GRANT ROLE
ana@db:~$ psql -h localhost -U bruno shop
shop=> SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = 'app';
 pg_terminate_backend 
----------------------
 t
(1 row)
shop=# REVOKE pg_monitor, pg_signal_backend FROM bruno;
REVOKE ROLE
```

The first refusal names both ways in: being a member of the role that owns the session, or holding
`pg_signal_backend`. With the role, the call returned `t` and the `app` session was terminated.
**It cannot touch a superuser's session**, whatever it is granted, which is what makes it safe to hand to an on-call engineer who is not an
administrator. Both grants were revoked at the end, because `bruno` is an analyst and neither
power is part of his job.
