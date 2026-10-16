---
title: A PostgreSQL of your own
version: 1
---

From this lesson on, boxoffice keeps its events in a database, so your machine needs one: **PostgreSQL
16, the release Ubuntu 24.04 ships**, which is the one `sql-databases` installs in its lesson 1. If you
took that course, your server is already running; check it with the first two commands below and skip
to the role. The `sql-databases` course comes after this one in the backend track, though, so if you
have not met it, this section is the whole of what you need.

## Three places to run it

| path | what it costs your computer | for this course |
|---|---|---|
| **installed** from Ubuntu's archive (recommended) | about 50 MB on disk, and a server process that holds a few tens of megabytes of memory while idle | every transcript runs as printed |
| **in the virtual machine** you may already use for Go | the same, inside the machine | the same |
| **in a container**, `postgres:16` from Docker Hub | a container engine first, which lesson 16 installs | works, with a password and a TCP address in place of the socket below |

The fourth path, a database hosted by a cloud company, needs an account and a network connection for
every query, and **a course should not depend on one company's free tier**, so it is not one of the
three. Install it if you can: the server is small, it starts with the machine, and its socket needs no
password, which keeps every command in these lessons short.

## Installing

These two commands install the server, the `psql` client and Ubuntu's tools around them. The lab
installed PostgreSQL with exactly these, and their screen of progress is not reproduced here:

```sh
sudo apt update
sudo apt install -y postgresql
```

Then ask what you got:

```
ana@vm:~/boxoffice$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/boxoffice$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
ana@vm:~/boxoffice$ psql -c "SELECT 1"
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

**Version 16, one cluster called `main` on port 5432, online.** A cluster is PostgreSQL's word for one
running server and its data directory. The last column is its log file, the first place to look when
something goes wrong. The refusal at the end is expected: PostgreSQL keeps its own list of users,
called **roles**, and the installer put only `postgres` on it.

## A role and a database

```
ana@vm:~/boxoffice$ sudo -u postgres createuser --superuser $USER
ana@vm:~/boxoffice$ createdb boxoffice
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT current_user, current_database()"
 current_user | current_database 
--------------+------------------
 ana          | boxoffice
(1 row)
```

`createuser`, run as `postgres`, adds a role with your login name; `--superuser` lets it do anything on
this server, which is right for a machine that is yours alone and wrong anywhere else. `createdb`
makes the database boxoffice will use. Neither printed anything, which is how both say they worked.

**No password was asked for at any point**, and none will be. `psql` and boxoffice connect through a
Unix socket in `/var/run/postgresql`, and Ubuntu's PostgreSQL trusts a socket connection from the
operating system user of the same name, which is called **peer authentication**. That is why the
address boxoffice will use names the socket's directory rather than a host and port:

```sh
export DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql'
```

Read it as: the PostgreSQL protocol, no host in the usual place, the database `boxoffice`, and the
socket directory as `host`. Put that line in `~/.profile` beside lesson 2's tokens, so every new
terminal has it.
