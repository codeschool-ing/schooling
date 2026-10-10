---
title: Reaching max_connections
version: 1
---

Because each connection is a process with memory and a slot in shared memory reserved for it, the
number of them is fixed when the server starts. Three settings decide it:

```
shop=# SHOW max_connections;
 max_connections 
-----------------
 100
(1 row)

shop=# SHOW superuser_reserved_connections;
 superuser_reserved_connections 
--------------------------------
 3
(1 row)

shop=# SHOW reserved_connections;
 reserved_connections 
----------------------
 0
(1 row)

shop=# SHOW shared_memory_size;
 shared_memory_size 
--------------------
 143MB
(1 row)
```

**`max_connections` is the total, and the last three slots of it are kept for superusers.**
`reserved_connections`, new in PostgreSQL 16, keeps further slots for roles granted
`pg_use_reserved_connections`, such as a monitoring role, and is zero by default.
`shared_memory_size` is what the server asked the kernel for at start, and it comes back in the
next section.

A hundred is far more than five terminals can fill, so lower it for a while. `max_connections`
has the context `postmaster` in `pg_settings`, which lesson 5 showed means a restart rather than a
reload. You also need an ordinary role to fill the ordinary slots, because `ana` is a superuser.
The simplest one to connect as is an operating-system user with a role of the same name, so that
peer authentication from lesson 3 lets it in:

```
ana@db:~$ sudo useradd --create-home app
ana@db:~$ createuser app
ana@db:~$ psql shop -c "GRANT SELECT, UPDATE ON customers, orders TO app"
GRANT
ana@db:~$ psql shop -c "ALTER SYSTEM SET max_connections = 5"
ALTER SYSTEM
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ psql shop -c "SHOW max_connections" -c "SHOW shared_memory_size"
 max_connections 
-----------------
 5
(1 row)

 shared_memory_size 
--------------------
 139MB
(1 row)
```

The `GRANT` lets `app` read and change the two tables, which a later section needs; lesson 12 is
about grants. Five slots, three of them reserved, leaves two for `app`.

## The first refusal

Open two terminals as `app`, each with a long query, so both ordinary slots are taken:

```sh
sudo -u app psql shop -c "SELECT pg_sleep(600)"
```

Then try a third:

```
ana@db:~$ sudo -u app psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  remaining connection slots are reserved for roles with the SUPERUSER attribute
ana@db:~$ psql shop -c "SELECT usename, count(*) FROM pg_stat_activity WHERE backend_type = 'client backend' GROUP BY usename"
 usename | count 
---------+-------
 ana     |     1
 app     |     2
(2 rows)

```

**`app` is refused, and `ana` still gets in**, into one of the reserved slots, which is exactly what
they are for: when an application has used up every ordinary slot, an administrator can still
connect, look and act. The count shows the two sessions of `app` and the one asking.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Five connection slots with max_connections set to 5. The first two are open to any role and are taken by app. The last three are reserved for superusers; one is taken by ana and two are free. A third connection as app is refused; ana is accepted into a reserved slot; when all five are taken every role is refused.\"><rect x=\"40\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"98.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 1</text><text x=\"98.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">app</text><rect x=\"168\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"226.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 2</text><text x=\"226.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">app</text><rect x=\"296\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"354.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 3</text><text x=\"354.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">ana</text><rect x=\"424\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"482.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 4</text><text x=\"482.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">free</text><rect x=\"552\" y=\"60\" width=\"116\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"610.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot 5</text><text x=\"610.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">free</text><text x=\"162.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">max_connections − 3: any role</text><text x=\"482.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">superuser_reserved_connections = 3</text><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A third connection as app: refused, the free slots are reserved for superusers.</text><text x=\"40\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A connection as ana, a superuser: accepted into a reserved slot.</text><text x=\"40\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Once all five are taken, by anybody: \"sorry, too many clients already\", for every role.</text></svg>", "caption": "Five slots, three of them kept for superusers. The reserve only helps while the roles filling the other slots are not superusers themselves."}
```

## The second refusal

The reserve only protects you from roles that are not superusers. Open three more terminals as
`ana`, each with its own `pg_sleep`, and all five slots are taken. Now nobody gets in, not even
the `postgres` role:

```
ana@db:~$ psql shop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
ana@db:~$ sudo -u postgres psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
```

**`sorry, too many clients already` means the reserve is gone too.** An application that connects
as a superuser takes reserved slots like any others, and on the day it leaks connections there is
no door left for the person trying to fix it. That alone is a reason for applications never to be
superusers, before lesson 11's other reasons.

## Getting back in

With no connection there is no SQL, so the way in is from the shell. A backend is a process, and
**`SIGTERM` to a backend is exactly what `pg_terminate_backend` sends**: the backend rolls back its
transaction and exits cleanly. `pkill` sends `SIGTERM` by default; `--full` matches the name `ps`
showed, and `--oldest` picks one:

```
ana@db:~$ sudo pkill --oldest --full 'postgres: 16/main: ana shop'
ana@db:~$ psql shop -c "SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE backend_type = 'client backend' AND pid <> pg_backend_pid()"
 count 
-------
     4
(1 row)

```

One slot freed was enough for a session, and that session ended the other four: every client
backend except its own, `pg_backend_pid()`. **Never use `kill -9` on a backend.** A backend that
dies without cleaning up may have left shared memory half changed, so the postmaster treats it as
a crash and restarts every process, the recovery lesson 8 showed. `SIGTERM` costs one session;
`SIGKILL` costs all of them. Restarting the whole service also gets you in, at the same price.
