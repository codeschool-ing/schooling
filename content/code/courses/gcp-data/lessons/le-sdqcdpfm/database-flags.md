---
title: Database flags, practised on the engine itself
version: 1
---

**A database flag is a setting of the engine, held by Cloud SQL and changed through its API.** On the
server in the cupboard, PostgreSQL reads `postgresql.conf` and `postgresql.auto.conf` from its data
directory. On Cloud SQL there is no directory you can reach, so the same settings are a list of
`name=value` pairs on the instance, `--database-flags`, which Cloud SQL writes into the engine's
configuration for you. **Each flag is one PostgreSQL setting, under its PostgreSQL name**, and
whether it can change under a running server is PostgreSQL's rule, not Google's. That is why this
section can practise flags on a laptop: the rule lives in the engine, and the engine is free.

## PostgreSQL 16 on the laptop

Ubuntu packages the same major version Cloud SQL runs for `POSTGRES_16`. Installing it also starts
a server of its own on port 5432, which this course does not use; the second line stops it and keeps
it from starting with the machine:

```sh
sudo apt-get install -y postgresql-16
sudo systemctl disable --now postgresql
```

On a WSL system without `systemd`, the second line is `sudo service postgresql stop`, and it has to
be repeated after each restart of WSL. The course's own server runs as you, in `~/gcp/pg`, on port
**5433**, so a forgotten system one on 5432 can never answer in its place. Ubuntu keeps the server's
programs out of the path, so add this to every terminal you use for this lesson and the next:

```sh
export PATH=/usr/lib/postgresql/16/bin:$PATH PGHOST=localhost PGPORT=5433 PGUSER=postgres
```

`PGHOST`, `PGPORT` and `PGUSER` are read by every PostgreSQL program, `psql` included, so none of the
commands below has to repeat them. Then create a cluster, the data directory a server runs from, and
start a server on it:

```
ana@laptop:~/gcp$ initdb -D ~/gcp/pg/orders -U postgres --auth=trust
The files belonging to this database system will be owned by user "ana".
This user must also own the server process.

The database cluster will be initialized with locale "C.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

creating directory /home/ana/gcp/pg/orders ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... America/Sao_Paulo
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

Success. You can now start the database server using:

    pg_ctl -D /home/ana/gcp/pg/orders -l logfile start

ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -o "-p 5433 -k $HOME/gcp/pg" -l ~/gcp/pg/orders.log start
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -Atc 'SELECT version()'
PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
```

**`-U postgres` names the superuser after the one Cloud SQL creates**, so that every command here is
the one you would type there. `--auth=trust` lets any local connection in without a password, which
is acceptable on a laptop whose server listens only on `localhost` and wrong anywhere else. Two lines
of the output are worth reading: `initdb` chose `max_connections` 100 and `shared_buffers` 128MB, its
own defaults for a machine it knows nothing about. `pg_ctl` starts the server, with `-p` for the port,
`-k` for the directory of its local socket, and `-l` for the file it logs to, because the system's
socket directory belongs to the system's PostgreSQL.

## Reading the settings, and which ones need a restart

**Every setting has a context**, PostgreSQL's own word for when it can change, and the catalogue view
`pg_settings` shows it beside the value:

```
ana@laptop:~/gcp$ psql -c "SELECT name, setting, unit, context FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'work_mem', 'log_min_duration_statement') ORDER BY name"
            name            | setting | unit |  context   
----------------------------+---------+------+------------
 log_min_duration_statement | -1      | ms   | superuser
 max_connections            | 100     |      | postmaster
 shared_buffers             | 16384   | 8kB  | postmaster
 work_mem                   | 4096    | kB   | user
(4 rows)
```

| context | when the setting can change | on Cloud SQL |
|---|---|---|
| `postmaster` | only when the server starts | setting the flag restarts the instance |
| `superuser`, `sighup` | on a reload of the configuration, no restart | the flag applies without one |
| `user` | for one session, by anybody, with `SET` | a flag sets the default; a session can still change its own |

**`max_connections` and `shared_buffers` are `postmaster`** because the memory for each connection
slot and for the buffer cache is laid out when the server starts. `shared_buffers` 16384 in units of
8 kB is the 128MB that `initdb` printed. `log_min_duration_statement`, which logs every statement
slower than its value, is `superuser`: a reload is enough. `work_mem`, the memory one sort or hash may
use before it spills to disk, is `user`, and the last block of this section uses that.

## Changing two of them

`ALTER SYSTEM` is how a superuser changes a setting on a running PostgreSQL. It writes the value into
`postgresql.auto.conf`, and `pg_reload_conf()` asks the server to read its configuration again:

```
ana@laptop:~/gcp$ psql -c "ALTER SYSTEM SET log_min_duration_statement = '500ms'" -c 'SELECT pg_reload_conf()' -c 'SHOW log_min_duration_statement'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

 log_min_duration_statement 
----------------------------
 500ms
(1 row)
```

**Applied on the reload.** Every statement slower than half a second now goes to the log, which is
the cheapest way there is to find the slow queries the first section said stay yours. The same with
the other one:

```
ana@laptop:~/gcp$ psql -c 'ALTER SYSTEM SET max_connections = 400' -c 'SELECT pg_reload_conf()' -c 'SHOW max_connections'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

 max_connections 
-----------------
 100
(1 row)
```

**Still 100.** The reload read the file, and the server could not apply a value it lays out only at
start, so it kept the old one and marked the difference:

```
ana@laptop:~/gcp$ psql -c "SELECT name, setting, pending_restart FROM pg_settings WHERE name = 'max_connections'"
      name       | setting | pending_restart 
-----------------+---------+-----------------
 max_connections | 100     | t
(1 row)

ana@laptop:~/gcp$ cat ~/gcp/pg/orders/postgresql.auto.conf
# Do not edit this file manually!
# It will be overwritten by the ALTER SYSTEM command.
log_min_duration_statement = '500ms'
max_connections = '400'
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders -l ~/gcp/pg/orders.log restart -m fast
waiting for server to shut down.... done
server stopped
waiting for server to start.... done
server started
ana@laptop:~/gcp$ psql -Atc 'SHOW max_connections'
400
```

**`pending_restart` is `t` until the server restarts, and then the value is 400.** That is the whole
behaviour Cloud SQL wraps. On an instance, setting `max_connections` with
`gcloud sql instances patch quitanda-orders --database-flags=…` restarts the instance, and
the command line warns before it does; setting `log_min_duration_statement` does not. Google's
documentation lists, for each supported flag, whether it needs a restart, and the list is the
`context` column above with another name.

**Two traps of the Cloud SQL command that the local one does not have**, both from Google's
documentation on configuring flags. `--database-flags` replaces the whole list each time: patching an
instance with `--database-flags=max_connections=400` removes the `log_min_duration_statement=500` that
the instance was created with, so every patch names every flag. And `--clear-database-flags` removes
them all, which the reference marks "WARNING: Instance will be restarted."

## What the engine refuses

```
ana@laptop:~/gcp$ psql -c 'ALTER SYSTEM SET max_conections = 400'
ERROR:  unrecognized configuration parameter "max_conections"
ana@laptop:~/gcp$ psql -c "ALTER SYSTEM SET work_mem = '64 potatoes'"
ERROR:  invalid value for parameter "work_mem": "64 potatoes"
HINT:  Valid units for this parameter are "B", "kB", "MB", "GB", and "TB".
```

**PostgreSQL checks the name and the value**, and so does Cloud SQL: a flag that is not on its list
for the engine version is refused, and so is a value outside the range the documentation gives for
it. Cloud SQL's list is shorter than PostgreSQL's settings. Some are not exposed at all, because
Google runs them: the port, the listen address, the data directory, the WAL archiving that its own
backups depend on. Some exist only on Cloud SQL, under names that begin `cloudsql.`, such as
`cloudsql.iam_authentication` from the previous section and `cloudsql.logical_decoding`, which lesson
25 turns on for change data capture. `gcloud sql flags list --database-version=POSTGRES_16` prints the
list for a version; it asks the API, so it was not run here.

## Why `postgres` on Cloud SQL cannot do this, and what it can do

```
ana@laptop:~/gcp$ psql -c 'CREATE ROLE quitanda_app LOGIN'
CREATE ROLE
ana@laptop:~/gcp$ psql -U quitanda_app -d postgres -c "ALTER SYSTEM SET work_mem = '64MB'"
ERROR:  permission denied to set parameter "work_mem"
ana@laptop:~/gcp$ psql -U quitanda_app -d postgres -c "SET work_mem = '64MB'" -c 'SHOW work_mem'
SET
 work_mem 
----------
 64MB
(1 row)
```

**A role that is not a superuser cannot change the server's configuration**, and that is the position
Cloud SQL's `postgres` user is in, as a member of `cloudsqlsuperuser` without PostgreSQL's
`SUPERUSER`. So the flags are the API's, and nothing a connection says changes them for the next
connection. **What any role can do is `SET` a `user` setting for its own session**: a report that
needs a large sort can ask for 64MB of `work_mem` for itself, and leave the default small for the
four hundred connections that do not. On Cloud SQL that is exactly as true, and it is the cheapest
tuning there is, because it changes one query and restarts nothing.

```
ana@laptop:~/gcp$ pg_ctl -D ~/gcp/pg/orders stop
waiting for server to shut down.... done
server stopped
```

The cluster stays in `~/gcp/pg/orders`, stopped, and lesson 7 starts it again.
