---
title: Installing PostgreSQL and making the bookshop's database
version: 1
---

From the prompt of your Ubuntu machine, two commands install the server, the `psql` client and
what they need:

```sh
sudo apt update
sudo apt install -y postgresql
```

`apt` prints a screen of progress, and its last lines are about creating a **cluster**,
PostgreSQL's word for one running server and the directory its data lives in. Ask what you got:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Version 16, one cluster called `main`, **`online`**, on port 5432, which is the port every
connection in this course names. The last column is the server's log, and the last section of this
lesson goes there for a reason the client is never told.

## A role and a database for the bookshop

The server keeps its own list of who may connect, separate from the users of the computer. Each
entry is a **role**, and the installer created exactly one, `postgres`. You are not on the list:

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

That refusal is good news of a kind. **A `FATAL:` line is the server answering**, so it is
installed, running and listening.

The bookshop will not connect as you, though. An application gets a role of its own, with a
password, and owns a database of its own, so that what it can touch is decided in one place.
Ubuntu lets the computer's `postgres` user act as the server's `postgres` role, so the two commands
run as that user:

```
ana@vm:~$ sudo -u postgres psql -c "CREATE ROLE bookshop LOGIN PASSWORD 'bookshop'"
CREATE ROLE
ana@vm:~$ sudo -u postgres createdb -O bookshop bookshop
```

The first is SQL, sent through `psql`: a role named `bookshop`, which may log in, with the password
`bookshop`. A password equal to the name is fine on a machine only you can reach and wrong anywhere
else; lesson 23 moves it out of the project's files. The second makes a database called `bookshop`
and, with `-O`, gives it to the new role, so the application may create its own tables there.
`createdb` printed nothing, which is how it says it worked.

## Two doors into the same server

The obvious next step is refused:

```
ana@vm:~$ psql -U bookshop bookshop
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "bookshop"
```

The password is not wrong; it was never asked for. `psql` with no host connects through a **socket
file** on this machine, and for that door Ubuntu's configuration uses **peer** authentication: the
server asks the operating system who is calling, gets `ana`, and refuses a login as `bookshop`.
Connecting to `localhost` goes through the other door, TCP on port 5432, where the rule is a
password. A connection URL names the host, so it takes that door:

```
ana@vm:~$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop
psql (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

bookshop=> SELECT current_user, current_database();
 current_user | current_database 
--------------+------------------
 bookshop     | bookshop
(1 row)
```

The URL reads left to right as protocol, user, password, host, port and database. **JDBC always
takes the TCP door**, so this is exactly the login the bookshop will make, and if this works, the
server side of everything that follows works too. The `SSL connection` line says the conversation is
encrypted even on one machine, because Ubuntu's PostgreSQL ships with a certificate.

`bookshop=>` is the prompt: the database you are in, and `>` because the role is not a superuser.
A statement ends at its semicolon. Commands that start with a backslash are `psql`'s own, and `\q`
is the one that leaves.
