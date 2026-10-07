---
title: Where a client keeps its password
version: 1
---

A person can type a password at a prompt. A program cannot, and neither can a script that runs at
three in the morning. libpq — the library underneath `psql` and most PostgreSQL clients — reads a
**password file**, `~/.pgpass`, with one line per server, port, database and role:

```
db.ipe.example:5433:ipe:bruno:<bruno's password>
```

In the lab Ana's file has a line for each of the six roles, because the lessons need to connect
as each of them. **A real one holds one person's passwords, never a team's.** Ana knowing Bruno's
password would make every log line that says `bruno` a line that could mean Ana.

The file is a secret on disk, and libpq checks how it is stored before it uses it:

```
ana@lab:~/gov$ ls -l ~/.pgpass
-rw-r--r-- 1 ana ana 269 Oct  7 02:09 /home/ana/.pgpass
ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "SELECT current_user"
WARNING: password file "/home/ana/.pgpass" has group or world access; permissions should be u=rw (0600) or less
Password for user bruno: 
WARNING: password file "/home/ana/.pgpass" has group or world access; permissions should be u=rw (0600) or less
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: fe_sendauth: no password supplied
ana@lab:~/gov$ chmod 600 ~/.pgpass
ana@lab:~/gov$ psql -h db.ipe.example -U bruno -c "SELECT current_user"
 current_user 
--------------
 bruno
(1 row)
```

With the file readable by every user on the machine, libpq refuses to use it — it warns, falls
back to asking at a prompt, and with no terminal to ask on, gives up. Made readable by Ana alone,
it works. **That refusal is the client protecting the password, not the server**, and it is the
model for every credential file in this course: the program that reads it should refuse one that
anybody else could have read.

## What a wrong password looks like

```
ana@lab:~/gov$ PGPASSWORD=lab-bruno-2025 psql -h db.ipe.example -U bruno -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "bruno"
connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "bruno"
ana@lab:~/gov$ PGPASSWORD=lab-bruno-2026 psql -h db.ipe.example -U nobody -c "SELECT 1"
psql: error: connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "nobody"
connection to server at "db.ipe.example" (127.0.0.1), port 5433 failed: FATAL:  password authentication failed for user "nobody"
```

Two things are worth seeing here.

**The message is the same for a wrong password and for a role that does not exist.** `nobody` is
not a role in this cluster, and the server answers exactly as it does for Bruno with last year's
password. Anything else would turn the login form into a way to ask which accounts exist, which
is the first thing somebody probing a database wants to know.

**Each attempt is printed twice.** The client tried once with an encrypted connection and once
without, and both were refused. That is libpq's default, `sslmode=prefer`, and lesson 3 is about
why "prefer" is the wrong word to trust.

The server, which knows more than it tells the client, writes the real reason into its own log.
Section 14 reads it.
