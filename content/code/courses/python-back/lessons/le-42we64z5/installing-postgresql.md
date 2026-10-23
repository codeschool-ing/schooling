---
title: Installing PostgreSQL 16, and pointing agenda at it
version: 1
---

Lesson 3 ended with registrations in a Python list, gone at every restart and wrong under two
requests at once. They need a database, and this course uses **PostgreSQL 16**, the version Ubuntu
24.04 ships. SQLite, which agenda has used so far, is a fine database for one writer at a time. A
site where many people register at once wants a server that takes row locks, which is the last
section of this lesson, and SQLite has none to take.

## Three places to have it

| path | what you get | what it costs your computer |
|---|---|---|
| **in your virtual machine** (recommended) | PostgreSQL 16 from Ubuntu's archive, as a service | the disk the package takes, and a server running in the background of the virtual machine |
| **installed on your own computer** | the installers from postgresql.org for Windows and macOS | the same, on the computer you also work on |
| **online** | a database a hosting company runs for you | nothing on your computer; a monthly bill or a free allowance on someone else's terms |

**The virtual machine is the one to pick**, and it is the same install the `sql-databases` course
uses in its lesson 1, so a student who takes that course later already has it. On your own computer,
the installers work and every query in this course runs the same, but the setup commands below are
Ubuntu's and were not run anywhere else. A hosted database works with Django unchanged, needs a
password and a host name instead of the local socket, and lesson 15 says how agenda reads those; it
was not used for this course, and nothing here depends on one company offering it.

## Installing it

In the virtual machine:

```sh
sudo apt update
sudo apt install -y postgresql
```

The package installs the server, the `psql` client and libpq, the C library every client uses to
talk to PostgreSQL, and starts a **cluster**: one running server with its data directory.

```
ana@vm:~/agenda$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~/agenda$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

One cluster, version 16, called `main`, on port 5432, **online**. The last column is its log file,
which is the first place to look when it misbehaves.

## A role and a database

PostgreSQL has its own list of users, called **roles**, and the only one it starts with is
`postgres`. Make one with your own login name, as `sql-databases` does, and then a database for
agenda:

```
ana@vm:~/agenda$ sudo -u postgres createuser --superuser $USER
```

```
ana@vm:~/agenda$ createdb agenda
```

Both print nothing when they work. `--superuser` lets your role do anything on this server, which
is right for a machine that is yours alone, and lesson 14's tests need part of it: Django creates a
separate database to run them in. **A role with your login name connects without a password** over
the local socket, because Ubuntu's PostgreSQL trusts the operating system to say who you are; that
is called **peer** authentication.

## The driver, and the setting

Django talks to PostgreSQL through **psycopg**, a Python library over libpq:

```
ana@vm:~/agenda$ uv add psycopg
Resolved 7 packages in 296ms
Prepared 1 package in 99ms
Installed 2 packages in 5ms
 + psycopg==3.3.6
 + typing-extensions==4.16.0
```

Then replace `DATABASES` in `config/settings.py`. No user, no password and no host: Django connects
as you, through the socket, to the database named `agenda`.

```
ana@vm:~/agenda$ sed -n '/^DATABASES/,/^}/p' config/settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'agenda',
    }
}
```

Django's built-in apps now get their tables in PostgreSQL. The first lines of `migrate` are the same
eighteen as lesson 2; these are its last:

```
ana@vm:~/agenda$ uv run python manage.py migrate | tail -3
  Applying auth.0011_update_proxy_permissions... OK
  Applying auth.0012_alter_user_first_name_max_length... OK
  Applying sessions.0001_initial... OK
```

The SQLite file is no longer used, so remove it with `rm db.sqlite3`. And ask PostgreSQL what it
holds now, with `psql` and its command for listing tables:

```
ana@vm:~/agenda$ psql agenda -c "\dt"
                  List of relations
 Schema |            Name            | Type  | Owner 
--------+----------------------------+-------+-------
 public | auth_group                 | table | ana
 public | auth_group_permissions     | table | ana
 public | auth_permission            | table | ana
 public | auth_user                  | table | ana
 public | auth_user_groups           | table | ana
 public | auth_user_user_permissions | table | ana
 public | django_admin_log           | table | ana
 public | django_content_type        | table | ana
 public | django_migrations          | table | ana
 public | django_session             | table | ana
(10 rows)
```

**The owner of every table is `ana`**, the role you made, because Django connected as it.
