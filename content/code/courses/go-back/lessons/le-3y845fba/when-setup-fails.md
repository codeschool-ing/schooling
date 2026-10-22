---
title: When the database will not answer
version: 1
---

A database connection fails in a handful of ways, and **each message says which, in its last clause**.
These were all produced on purpose, on the machine of the last section.

## The role or the database is missing

```
ana@vm:~/boxoffice$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

`psql` with no database name tries one named after you, and there is none. **`role "ana" does not
exist`**, the message from the last section, means the `createuser` step was skipped; **`database
"ana" does not exist`** means you got in and asked for the wrong database. The fix for the second is
to name one, `psql boxoffice`; naming one that does not exist gets the same refusal, with that name:

```
ana@vm:~/boxoffice$ psql nowhere -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "nowhere" does not exist
```

## The server is not running

```
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main stop
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
	Is the server running locally and accepting connections on that socket?
ana@vm:~/boxoffice$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~/boxoffice$ sudo pg_ctlcluster 16 main start
```

**`No such file or directory` on the socket means nothing is listening**: the socket file only exists
while the server runs. `pg_lsclusters` confirms it with `down`, and `pg_ctlcluster 16 main start`
brings it back. If it will not start, the log file in the last column of `pg_lsclusters` says why, and
the two usual reasons are a full disk and another program already holding port 5432.

## A password is asked for

```
ana@vm:~/boxoffice$ psql -h localhost -w boxoffice -c "SELECT 1"
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: fe_sendauth: no password supplied
```

`-h localhost` connects over TCP instead of the socket, and **Ubuntu's PostgreSQL asks for a password
on TCP connections, even from the same machine**; `-w` tells `psql` not to prompt, so it fails at once
instead of waiting. The cure is not to give your role a password: it is to use the socket, which is what
`host=/var/run/postgresql` in `DATABASE_URL` does. If a tool insists on TCP, a password set with
`ALTER ROLE` in `psql` is the way, and it then has to travel in the URL or in a `~/.pgpass` file.

## And from boxoffice's side

boxoffice in section 09 checks both of its own preconditions before it opens a port:

```
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN=x go run .
2026/10/16 19:56:40 no database: set DATABASE_URL
exit status 1
ana@vm:~/boxoffice$ BOXOFFICE_MANAGER_TOKEN=x DATABASE_URL='postgres:///nowhere?host=/var/run/postgresql' go run .
2026/10/16 19:56:41 database: failed to connect to `user=ana database=nowhere`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): server error: FATAL: database "nowhere" does not exist (SQLSTATE 3D000)
exit status 1
```

The second error is pgx's, and it reads like the ones above: which user and database it tried, through
which socket, and PostgreSQL's own answer with its **SQLSTATE**, `3D000`, the five-character code every
PostgreSQL error carries. Section 08 uses two of those codes on purpose.
