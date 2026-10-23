---
title: When PostgreSQL refuses
version: 1
---

Setting up a database server has more ways to fail than installing a library, and each of them
prints a message that names the cause. These were met in this order while setting up agenda, one
step at a time, which is also the order you would meet them in if a step of the previous section
were skipped. Each command keeps only the last line of the traceback, where the cause is.

## No driver

```
ana@vm:~/agenda$ uv run python manage.py migrate 2>&1 | tail -1
django.core.exceptions.ImproperlyConfigured: Error loading psycopg2 or psycopg module
```

`DATABASES` names PostgreSQL and Django cannot import a library to talk to it. **`uv add psycopg`**,
in the project, fixes it. If the error persists, the library went into a different environment:
check that the command runs through `uv run`.

## No role

```
ana@vm:~/agenda$ uv run python manage.py migrate 2>&1 | tail -1
django.db.utils.OperationalError: connection failed: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The connection reached the server, which is good news, and the server does not know the name `ana`.
Run **`sudo -u postgres createuser --superuser $USER`**. The socket path in the message,
`/var/run/postgresql/.s.PGSQL.5432`, says which server answered: the local one, on the default port.

## No database

```
ana@vm:~/agenda$ uv run python manage.py migrate 2>&1 | tail -1
django.db.utils.OperationalError: connection failed: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "agenda" does not exist
```

One step further: the role exists and the database does not. **`createdb agenda`**. A typo in
`NAME` in `settings.py` produces this same message with the misspelled name in it, which is how to
tell the two apart.

## No server

Stop the server on purpose, and ask Django a question that needs it:

```
ana@vm:~/agenda$ sudo systemctl stop postgresql
ana@vm:~/agenda$ uv run python manage.py showmigrations events 2>&1 | tail -1
	Is the server running locally and accepting connections on that socket?
ana@vm:~/agenda$ sudo systemctl start postgresql && pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

The last line of a longer message: the socket file does not exist because nothing is listening.
**Start the server**, with `sudo systemctl start postgresql`, and `pg_lsclusters` says `online` again.
If it will not start, the log file in the last column of `pg_lsclusters` says why, and
`sudo tail /var/log/postgresql/postgresql-16-main.log` reads it. A full disk and a port already in
use are the two usual causes.

## Peer authentication failed

One more, which these steps avoid and which you will meet the first time a project's settings name a
`USER` that is not your login: `FATAL: Peer authentication failed for user "agenda"`. Over the local
socket, Ubuntu's PostgreSQL only accepts a role whose name matches the operating-system user
connecting. A role for an application, with a password, connects over TCP instead, with
`'HOST': 'localhost'` in the settings, and lesson 15 does exactly that. This one was not produced
for this course.
