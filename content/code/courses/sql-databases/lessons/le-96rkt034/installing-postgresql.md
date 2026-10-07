---
title: Installing PostgreSQL, and the first conversation with it
version: 1
---

From the prompt of your Ubuntu machine, two commands install the server, the `psql` client and
everything they need:

```sh
sudo apt update
sudo apt install -y postgresql
```

`sudo` asks for your password, and `apt` prints a screen of progress for a minute or two. Its last
lines are about creating a **cluster**, which is PostgreSQL's word for one running server and the
directory its data lives in. Ask what you got:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Version 16, one cluster called `main`, listening on port 5432, **`online`**. The last column is
where it writes its log, and it is the first place to look when something goes wrong.

## You, as the database knows you

PostgreSQL keeps its own list of who may connect, separate from the users of the computer. The
installer put exactly one name on it, `postgres`, and you are not it:

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

A **role** is a database user. Make one with your name, as `postgres`, who is allowed to:

```
ana@vm:~$ sudo -u postgres createuser --superuser $USER
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

`createuser` printed nothing, which is how it says it worked. `--superuser` lets your role do
anything on this server — right for a machine that is yours and nobody else's, and wrong anywhere
else. `$USER` is your username, filled in by the shell.

The second refusal is a different one, and an improvement. You got in; there was nothing to get
into. `psql` with no name connects to a **database** called the same as you, and none exists. One
server holds many databases, and this course uses one called `shop`:

```
ana@vm:~$ createdb shop
```

## One line of configuration

`psql` prints a missing value as nothing at all, which looks exactly like an empty piece of text.
Lesson 1 is about to spend a whole section on the difference, so make it visible. This writes a
file `psql` reads every time it starts:

```sh
cat > ~/.psqlrc <<'RC'
\set QUIET on
\pset null NULL
\unset QUIET
RC
```

The middle line is the setting — show a missing value as the word `NULL`. The lines around it
stop `psql` announcing the change every time you open it.

## The first conversation

```
ana@vm:~$ psql shop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
Type "help" for help.

shop=# SELECT 1 + 1 AS two;
 two 
-----
   2
(1 row)

shop=# SELECT NULL AS nothing;
 nothing 
---------
 NULL
(1 row)

shop=# \q
```

**`shop=#` is the prompt**: the database you are in, and `#` because your role is a superuser.
A statement ends at its semicolon, and until you type one `psql` waits, with the prompt turned
into `shop-#` to say it is still listening. Commands that start with a backslash are `psql`'s own
rather than SQL, need no semicolon, and `\q` is the one that leaves.

That is the whole environment. The shop's tables arrive at the end of this lesson, once you know
what a table is.
