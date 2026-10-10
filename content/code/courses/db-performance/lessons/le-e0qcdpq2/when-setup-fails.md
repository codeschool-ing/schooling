---
title: When the setup does not work
version: 1
---

Everything in the last section can go wrong, and almost every way it goes wrong prints a sentence
saying which. Read the sentence before anything else: the part after `FATAL:` or `ERROR:` is the
server telling you exactly what it refused.

## `role "…" does not exist`

```
ana@vm:~$ psql market
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The server is running and does not know you. The `createuser` step was skipped, or it was run on
a different machine from the one you are typing in. Run it:

```sh
sudo -u postgres createuser --superuser $USER
```

If the next attempt says `database "market" does not exist`, you got further: the server knows
you now, and `createdb market` is the step that is missing.

## `No such file or directory` on the socket

```
ana@vm:~$ sudo systemctl stop postgresql
ana@vm:~$ psql market
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  the database system is shutting down
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~$ sudo systemctl start postgresql
```

`psql` looked for the server's socket file, which is how two programs on one computer talk, and
there was none, because the server is not running. `pg_lsclusters` says so in its fourth column:
`down`. The transcript stopped it on purpose; on your machine, the usual cause is that the virtual
machine was restarted and the service did not come back, or that a setting you changed stopped
it from starting. `sudo systemctl start postgresql` starts it, and if it goes straight back to
`down`, the last lines of the log file in the last column say why:

```sh
sudo tail -n 20 /var/log/postgresql/postgresql-16-main.log
```

## `relation "…" already exists`

```
ana@vm:~$ psql market -v ON_ERROR_STOP=1 -f market.sql
 setseed 
---------
 
(1 row)

Time: 1.615 ms
psql:market.sql:10: ERROR:  relation "sellers" already exists
Time: 4.440 ms
```

`market.sql` was loaded into a database that already had the tables, usually because the first
load was interrupted, or because it is the second time. `ON_ERROR_STOP` stopped it at the first
table, so nothing was added twice. Do not try to finish a half-done load by hand. Throw the
database away and make it again; it is two commands and two minutes:

```sh
dropdb market
createdb market
psql market -v ON_ERROR_STOP=1 -f market.sql
```

## The load is very slow, or the machine stops answering

The load writes 1.3 GB and then reads all of it back for `VACUUM ANALYZE`. On a virtual machine
with 2 GB of memory and a slow disk it can take ten minutes or more, and that is slowness rather
than failure: the `INSERT` lines keep arriving, one by one. Two things make it worse and are
worth checking:

- **The disk is full.** `df -h /` shows the space left. The database needs about 1.5 GB while
  it loads, and the course's later copies of it more; the 30 GB disk the setup recommends leaves
  room for all of them.
- **The machine has too little memory**, and the host computer is swapping. Close what you can
  on the host, or give the virtual machine 2 GB and accept slower timings throughout.

## When none of these is it

Copy the whole error, starting at the line that says `ERROR` or `FATAL`, and search for it in
quotes. PostgreSQL's messages are fixed sentences, so somebody has met yours before; the part in
quotes after it — a role, a table, a file — is the part that is specific to you, and is usually
where the answer is.
