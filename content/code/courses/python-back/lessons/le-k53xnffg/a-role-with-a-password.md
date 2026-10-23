---
title: A database role with a password
version: 1
---

Lesson 4 connected as ana, a superuser, through the local socket, with no password. A server's
application connects as **a role of its own**, with a password, over TCP, and owns its database and
nothing else, so that a bug or a leak in agenda reaches agenda's data and not the server's.

Add the three values to `.env`, the password generated as the key was, and create the role with it.
The password goes to `psql` through a variable, so it never appears in a command or the shell's
history:

```
ana@vm:~/agenda$ printf 'DATABASE_USER=agenda_app\nDATABASE_PASSWORD=%s\nDATABASE_HOST=localhost\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')" >> .env
ana@vm:~/agenda$ echo "create role agenda_app login createdb password :'pw'" | sudo -u postgres psql -v pw="$(sed -n 's/^DATABASE_PASSWORD=//p' .env)"
CREATE ROLE
```

`createdb` lets the role create the database pytest-django makes for each run, which is right for a
development machine and not for production. Then hand it agenda's tables and the database itself;
both were ana's:

```
ana@vm:~/agenda$ sudo -u postgres psql agenda -c "reassign owned by ana to agenda_app" -c "alter database agenda owner to agenda_app"
REASSIGN OWNED
ALTER DATABASE
```

## Two refusals

Without a host, `psql` uses the socket, and the socket uses peer authentication, which lesson 4
promised you would meet:

```
ana@vm:~/agenda$ psql -U agenda_app agenda -c "select current_user"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "agenda_app"
```

**`Peer authentication failed`**: over the socket, Ubuntu's PostgreSQL only lets in a role named like
the operating-system user connecting, and there is no user `agenda_app`. Over TCP, it asks for a
password instead, and checks it:

```
ana@vm:~/agenda$ PGPASSWORD=wrong psql -h localhost -U agenda_app agenda -c 'select current_user'
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "agenda_app"
connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "agenda_app"
```

With the right one, from `.env`, through Django:

```
ana@vm:~/agenda$ uv run --env-file .env python manage.py dbshell -- -c "select current_user, inet_server_addr()"
 current_user | inet_server_addr 
--------------+------------------
 agenda_app   | 127.0.0.1
(1 row)

ana@vm:~/agenda$ uv run --env-file .env pytest -q
.................                                                                            [100%]
17 passed in 8.92s
```

`dbshell` passed the settings to `psql`: **agenda_app, at 127.0.0.1**, over TCP. The tests ran as
that role too, creating and dropping their database.
