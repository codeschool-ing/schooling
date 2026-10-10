---
title: What a dump of one database leaves out
version: 1
---

Lesson 1 restored into a second database on the same server, which is the kindest possible test:
everything the dump assumed was already there. A real disaster leaves you with a **new server**,
and that is the test worth running. Ubuntu makes a second one on the same machine with one
command:

```
ana@vm:~$ sudo pg_createcluster 16 restore --port 5433 --start
Creating new PostgreSQL cluster 16/restore ...
/usr/lib/postgresql/16/bin/initdb -D /var/lib/postgresql/16/restore --auth-local peer --auth-host scram-sha-256 --no-instructions
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /var/lib/postgresql/16/restore ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Ver Cluster Port Status Owner    Data directory                 Log file
16  restore 5433 online postgres /var/lib/postgresql/16/restore /var/log/postgresql/postgresql-16-restore.log
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory                 Log file
16  main    5432 online postgres /var/lib/postgresql/16/main    /var/log/postgresql/postgresql-16-main.log
16  restore 5433 online postgres /var/lib/postgresql/16/restore /var/log/postgresql/postgresql-16-restore.log
ana@vm:~$ psql -p 5433 -d postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5433" failed: FATAL:  role "ana" does not exist
```

`pg_createcluster` ran `initdb`, which builds an empty data directory, and started the result on
port 5433. `pg_lsclusters` now has two lines: two servers, each with its own files, its own
configuration and its own log, sharing nothing but the computer. From now on `-p 5433` talks to
the new one.

And the new server does not know you. **Your own role was never in any dump**, because roles do not
belong to a database. They belong to the whole server, and every database on it shares them.
Create yourself there, then a database to restore into, and restore:

```
ana@vm:~$ sudo -u postgres createuser -p 5433 --superuser $USER
ana@vm:~$ createdb -p 5433 shop
ana@vm:~$ pg_restore -p 5433 -d shop shop.dump
pg_restore: error: could not execute query: ERROR:  role "shop_owner" does not exist
Command was: ALTER TABLE public.customers OWNER TO shop_owner;

pg_restore: error: could not execute query: ERROR:  role "shop_owner" does not exist
Command was: ALTER TABLE public.orders OWNER TO shop_owner;

pg_restore: error: could not execute query: ERROR:  role "shop_app" does not exist
Command was: GRANT SELECT,INSERT ON TABLE public.customers TO shop_app;


pg_restore: error: could not execute query: ERROR:  role "shop_app" does not exist
Command was: GRANT SELECT,INSERT ON TABLE public.orders TO shop_app;


pg_restore: warning: errors ignored on restore: 4
ana@vm:~$ echo $?
1
```

Four errors, one per line of the dump that named a role this server has never heard of: the
tables cannot be given to `shop_owner`, and `shop_app` cannot be granted anything. `pg_restore`
carried on past each one, said `errors ignored on restore: 4` and **exited with status 1**. The
rows are all there; the tables are owned by you, and the application's role would be refused at
its first query. A script that ignores the exit status calls this a successful restore.

## Globals

What lives outside every database is called **global**: the roles, with their passwords and
attributes, and the tablespaces. A dump of one database cannot hold them, whichever format it is in:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A box for one PostgreSQL server. Across its top, a strip of global objects, the roles with their passwords and the tablespaces, which belong to no database. Below it, two databases, shop and bigshop, each holding tables, rows, indexes, keys and grants. pg_dump shop reaches into one database only; pg_dumpall --globals-only reaches only the strip; a complete backup needs both.\"><defs><marker id=\"l2s-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l2s-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"440\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one PostgreSQL server</text><rect x=\"40\" y=\"52\" width=\"400\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">global: shared by every database</text><text x=\"160\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">roles and their passwords</text><text x=\"350\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tablespaces</text><rect x=\"40\" y=\"124\" width=\"190\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">database shop</text><text x=\"135\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tables, rows, indexes,</text><text x=\"135\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">keys, grants</text><rect x=\"250\" y=\"124\" width=\"190\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"345\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">database bigshop</text><text x=\"345\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tables, rows, indexes,</text><text x=\"345\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">keys, grants</text><rect x=\"500\" y=\"60\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">pg_dumpall --globals-only</text><path d=\"M500 80 L444 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2s-am)\"></path><rect x=\"55\" y=\"252\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">pg_dump shop</text><path d=\"M135 252 L135 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2s-ph)\"></path></svg>", "caption": "What lives where. A dump of one database never contains the roles its grants name, because roles belong to the whole server; the globals are a second file, and a backup is both."}
```

`pg_dumpall --globals-only` dumps exactly the global part, as plain SQL:

```
ana@vm:~$ pg_dumpall --globals-only -f globals.sql
ana@vm:~$ grep -E '^(CREATE|ALTER) ROLE' globals.sql
CREATE ROLE ana;
ALTER ROLE ana WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE shop_app;
ALTER ROLE shop_app WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:WasJ/NKVQHsRPGO7PHzYIQ==$DR6YU7hfJ+NGKYBPwrGW+S+wyufhd9St8g29KIK2mMc=:WrtE9UsOMp9lPnUxa2b55rJ01dE64Yrg1234UY0RFXg=';
CREATE ROLE shop_owner;
ALTER ROLE shop_owner WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOREPLICATION NOBYPASSRLS;
```

Every role on the server, including `postgres` and you, with what each may do. `shop_app` carries
its password, stored as a **SCRAM** hash rather than as the text `app-secret-1`, which means the
restored server accepts the same password without anybody knowing it. It also means **this file is
a secret**: anyone holding it can attack those hashes at leisure. Keep it where the dumps are kept
and protect both the same way; lesson 9 decides how.

## The restore that works

Start again with the globals first:

```
ana@vm:~$ dropdb -p 5433 shop
ana@vm:~$ psql -p 5433 -d postgres -f globals.sql
SET
SET
SET
psql:globals.sql:16: ERROR:  role "ana" already exists
ALTER ROLE
psql:globals.sql:18: ERROR:  role "postgres" already exists
ALTER ROLE
CREATE ROLE
ALTER ROLE
CREATE ROLE
ALTER ROLE
ana@vm:~$ createdb -p 5433 shop
ana@vm:~$ pg_restore -p 5433 -d shop shop.dump
ana@vm:~$ echo $?
0
ana@vm:~$ psql -X -A -t -p 5433 shop -f verify.sql > restored.txt
ana@vm:~$ psql -X -A -t shop -f verify.sql > live.txt
ana@vm:~$ diff live.txt restored.txt && echo identical
identical
```

The two `ERROR` lines are `CREATE ROLE` for `ana` and `postgres`, who already exist on the new
server; the `ALTER ROLE` after each still runs and sets their attributes. Every other role is
created. This time `pg_restore` is silent and exits with 0, and the report from lesson 1 says the
two servers hold the same shop.

**A backup of a PostgreSQL server is therefore two files, not one**: the globals, and one dump per
database. A job that dumps the databases and forgets the globals produces copies that restore
with errors and an application that cannot log in, and the first time anybody finds out is on a
new server. `pg_dumpall` without `--globals-only` writes everything into one plain SQL file, roles
and every database, and that file has all of plain SQL's weaknesses; the usual arrangement is the
globals with `pg_dumpall` and each database with `pg_dump -Fc`.
