---
title: Passwords, and where they must not end up
version: 1
---

Peer authentication works for somebody sitting at the server. Everybody else, the application on
another machine and the analyst on his laptop, comes over the network, and Ubuntu's `pg_hba.conf`
asks a network connection for a **password checked with `scram-sha-256`**. Three things matter
about that password: how the server keeps it, how you set it without leaving it lying around, and
how a program supplies it without anybody typing.

## How the server keeps it

**The server does not store the password.** It stores a SCRAM verifier: a salted value derived
from the password through thousands of rounds of hashing, from which the password cannot be read
back. With it, the client and the server each prove to the other that they know the password
without sending it across. Set two with psql's `\password`, typing `bruno-lab-only` for `bruno` and
`app-lab-only` for `app`; the next lessons log in with them:

```
shop=# SHOW password_encryption;
 password_encryption 
---------------------
 scram-sha-256
(1 row)

shop=# \password bruno
Enter new password for user "bruno": 
Enter it again: 
shop=# \password app
Enter new password for user "app": 
Enter it again: 
shop=# SELECT rolname, split_part(rolpassword, ':', 1) AS stored FROM pg_authid WHERE rolname IN ('bruno', 'app');
 rolname |       stored       
---------+--------------------
 bruno   | SCRAM-SHA-256$4096
 app     | SCRAM-SHA-256$4096
(2 rows)
```

The query shows only the start of what was stored, the method and the 4096 rounds of hashing; the
rest is the salt and the two keys. Only a superuser may read `pg_authid` at all.

**`password_encryption` has been `scram-sha-256` by default since version 14.** Before that it was
`md5`, a weaker scheme whose stored value is as good as the password to anybody who steals it. A
cluster upgraded from an older version keeps every `md5` value until that password is set again.
`SELECT rolname FROM pg_authid WHERE rolpassword LIKE 'md5%'` finds them, and PostgreSQL 18 warns
whenever a new one is set.

## Where a password must not end up

`\password` asked twice, showed nothing, and sent the server a verifier computed by psql: **the
password itself never crossed the connection and was never part of any statement**. The other way
to set one is `ALTER ROLE bruno PASSWORD '…'`, and that statement carries the password in clear
text to every place a statement can go. Here is one, with a typo in the role's name:

```
shop=# ALTER ROLE brunno PASSWORD 'bruno-lab-only';
ERROR:  role "brunno" does not exist
ana@db:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:06.155 -03 [320] ana@shop ERROR:  role "brunno" does not exist
2026-10-10 04:26:06.155 -03 [320] ana@shop STATEMENT:  ALTER ROLE brunno PASSWORD 'bruno-lab-only';
```

The server logs the text of a statement that fails, by default, so the error came with `bruno`'s
password beside it, in a file every administrator reads and every log collector ships elsewhere.
On a real server, that password is now somebody else's to know, and the only fix is a new one.
Statements that succeed reach the log too when lesson 19's `log_statement` is turned up, and
interactive psql keeps everything you type in `~/.psql_history`. Typing
`psql -c "ALTER ROLE … PASSWORD '…'"` at the shell adds `~/.bash_history` to the list.

**So a password is set with `\password`, or by a program that sends a verifier, and never written
into a statement by hand.**

## A password file for programs

A person types a password at the prompt. A program cannot, and a password pasted into every
script that connects is one more copy in every repository and backup those scripts reach. libpq,
the library under psql and most drivers, reads **`~/.pgpass`** instead: one line per connection, five fields separated by colons,
and `*` matching anything. Write it with an editor, so the passwords go into no shell history:

```conf
# ~/.pgpass: hostname:port:database:username:password
localhost:5432:*:bruno:bruno-lab-only
localhost:5432:*:app:app-lab-only
```

`-h localhost` makes psql use the network door, where a password is asked for, and `-w` tells it
never to prompt, so a missing password is an error at once instead of a question nobody answers.
The first try fails for a reason that is printed and easy to miss:

```
ana@db:~$ ls -l ~/.pgpass
-rw-rw-r-- 1 ana ana 126 Oct 10 04:26 /home/ana/.pgpass
ana@db:~$ psql -w -h localhost -U app shop -c "SELECT current_user;"
WARNING: password file "/home/ana/.pgpass" has group or world access; permissions should be u=rw (0600) or less
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: fe_sendauth: no password supplied
ana@db:~$ chmod 600 ~/.pgpass
ana@db:~$ psql -w -h localhost -U app shop -c "SELECT current_user;"
 current_user 
--------------
 app
(1 row)

ana@db:~$ psql -w -h localhost -U bruno shop -c "SELECT current_user;"
 current_user 
--------------
 bruno
(1 row)
```

**libpq ignores a password file that other users can read**, and says so in a warning rather than
an error. In a script that throws away its warnings, all that is left is `no password supplied`,
which sends people looking at the server. From now on, `psql -h localhost -U bruno shop` is how
this course logs in as somebody else, with the password the role really has, through the same door
the application uses.

## A password with an end date

`VALID UNTIL` puts an expiry date on a role's password. Set one in the past on `app`:

```
shop=# ALTER ROLE app VALID UNTIL '2026-01-01';
ALTER ROLE

shop=# \du app
                      List of roles
 Role name |                 Attributes                  
-----------+---------------------------------------------
 app       | Password valid until 2026-01-01 00:00:00-03
ana@db:~$ psql -w -h localhost -U app shop
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "app"
password retrieved from file "/home/ana/.pgpass"
connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "app"
password retrieved from file "/home/ana/.pgpass"
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:26:07.883 -03 [334] app@shop FATAL:  password authentication failed for user "app"
2026-10-10 04:26:07.883 -03 [334] app@shop DETAIL:  User "app" has an expired password.
	Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
```

The client is told only that authentication failed, twice, because psql tried once with
encryption and once without. **The reason is in the server's log and only there**: the password was
right and has expired, and the connection matched line 125 of `pg_hba.conf`. Telling a stranger
which part of a login was wrong would help the stranger, so the server keeps it for whoever reads
the log, and that is the first place to look when a login fails.

`VALID UNTIL` is about the password and nothing else. A role that logs in by peer, like `ana`, is
not affected by it, and neither is a session that is already open. It is a date for a credential,
not an account that switches itself off; `NOLOGIN` is that. Put `app` back:

```
shop=# ALTER ROLE app VALID UNTIL 'infinity';
ALTER ROLE

shop=# \du
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 ana       | Superuser, Create role, Create DB
 app       | Password valid until infinity
 bruno     | 
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
 reporting | Cannot login

shop=# \drg
               List of role grants
 Role name | Member of |   Options    | Grantor  
-----------+-----------+--------------+----------
 bruno     | reporting | INHERIT, SET | postgres
(1 row)
```

That is where lesson 12 starts: a group with no privileges, an analyst in it with the default
options, and an application. The analyst and the application have passwords, and both are in
`~/.pgpass`.
