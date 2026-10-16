---
title: What the package did, and a role with your name
version: 1
---

The installer did three things to the machine besides copying programs, and each one explains a
refusal you are about to meet.

It created an **operating-system user called `postgres`**. The server runs as that user, owns
every data file as that user, and nobody else on the machine can read them — including you,
without `sudo`. That is a security boundary, and it is also why the server's files survive a
mistake you make in your own home directory.

It created a **database role called `postgres`**, the first and only one, with every privilege
there is. A **role** is the database's own idea of a user, kept inside the cluster and separate
from the users of the computer. Lesson 11 is about the difference.

And it wrote a rule saying that **a connection from this machine, over the local socket, is
allowed only for the database role whose name matches the operating-system user making it**.
That rule is called **peer authentication**, and it is why the first attempt fails:

```
ana@db:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

The server is running and does not know you. It knows `postgres`, and peer authentication will let
the operating-system user `postgres` in as that role. `sudo -u postgres` runs a command as that
user:

```
ana@db:~$ sudo -u postgres psql -c "SELECT current_user, version();"
 current_user |                                                                 version                                                                  
--------------+------------------------------------------------------------------------------------------------------------------------------------------
 postgres     | PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
(1 row)
```

That is the door an administrator always has on a packaged server. Use it now to give yourself a
role of your own, and a database to land in:

```
ana@db:~$ sudo -u postgres createuser --superuser $USER
ana@db:~$ createdb $USER
ana@db:~$ psql
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
Type "help" for help.

ana=# \conninfo
You are connected to database "ana" as user "ana" via socket in "/var/run/postgresql" at port "5432".

ana=# SHOW data_directory;
       data_directory        
-----------------------------
 /var/lib/postgresql/16/main
(1 row)

ana=# SHOW config_file;
               config_file               
-----------------------------------------
 /etc/postgresql/16/main/postgresql.conf
(1 row)

ana=# \q
```

`createuser` printed nothing, which is how it says it worked, and neither did `createdb`. `$USER`
is your username, filled in by the shell, so the role is called whatever you are called.
`--superuser` lets that role do anything on this cluster. **On a server of your own that you are
here to administer, that is right. Anywhere else it is wrong**, and lessons 11 and 12 are about
how roles are given exactly what they need and nothing more.

`psql` with no arguments connects as the role named like you, to the database named like you,
which is why `createdb $USER` came first. The prompt `ana=#` is the database you are in, and `#`
says the role is a superuser; an ordinary role sees `>`.

**`data_directory` and `config_file` are in different places**, which is a choice Debian and
Ubuntu make and the PostgreSQL project does not. Upstream, the configuration lives inside the data
directory. Lesson 4 opens the first and lesson 5 the second.

## The processes, from outside

The same server, seen by the operating system rather than by systemd:

```
ana@db:~$ ps -u postgres -o pid,cmd
    PID CMD
   2487 /usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/16/main -c config_file=/etc/postgresql/16/main/postgresql.conf
   2488 postgres: 16/main: checkpointer 
   2489 postgres: 16/main: background writer 
   2491 postgres: 16/main: walwriter 
   2492 postgres: 16/main: autovacuum launcher 
   2493 postgres: 16/main: logical replication launcher 
```

Every process belongs to the user `postgres`. Nothing is connected right now, so there are only
the postmaster and its workers. The process ids on your machine will be different numbers.

## Two refusals worth recognising now

The socket in those error messages, `/var/run/postgresql/.s.PGSQL.5432`, is a file the server
creates when it starts. It is how a client on the same machine finds it, and the rule above is
the rule for that door. Asking to connect as somebody you are not is refused at it:

```
ana@db:~$ psql -U postgres
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "postgres"
```

And the other door, the network one on port 5432, has a different rule: **a password**. Your role
has none, so the server asks and gets nothing:

```
ana@db:~$ psql -h localhost
Password for user ana: 
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: fe_sendauth: no password supplied
```

`-h localhost` made `psql` connect over TCP instead of the socket, even though the server is on
the same machine. Both rules come from one file, `pg_hba.conf`, and lesson 5 reads it line by
line. For this course the socket and peer authentication are all you need.
