---
title: pg_hba.conf, line by line
version: 1
---

Lesson 3 met two refusals: a socket connection as somebody you are not, and a network connection
with no password. Both came from one file, `pg_hba.conf`, whose name stands for host-based
authentication. **It decides who may connect, from where, to which database, and how they prove
who they are**, and it does it with a short list read from the top, where the first line that
matches a connection is the only line that counts.

## The seven lines

Like `postgresql.conf`, it is mostly comments, and only `postgres` can read it:

```
ana@db:~$ sudo grep -n -Ev '^\s*(#|$)' /etc/postgresql/16/main/pg_hba.conf
118:local   all             postgres                                peer
123:local   all             all                                     peer
125:host    all             all             127.0.0.1/32            scram-sha-256
127:host    all             all             ::1/128                 scram-sha-256
130:local   replication     all                                     peer
131:host    replication     all             127.0.0.1/32            scram-sha-256
132:host    replication     all             ::1/128                 scram-sha-256
```

The `-n` kept the line numbers, which matter: the server quotes them in the log. Here are the
same lines with what each one does:

```schooling-example
{"language": "conf", "file": "/etc/postgresql/16/main/pg_hba.conf", "parts": [{"code": "local   all             postgres                                peer", "note": "Line 118. Over the socket, the role `postgres` is let in when the operating-system user is also `postgres`, which is what `sudo -u postgres psql` relies on. The comment above it in the file says not to disable it: Ubuntu's maintenance jobs connect this way."}, {"code": "# TYPE  DATABASE        USER            ADDRESS                 METHOD", "note": "The file's own header, a few lines below the first rule. A line has a connection type, the database, the role, an address for network types, and the method that decides whether to believe the client. A connection is compared with the lines from the top, and the first line whose four columns all match decides; nothing below it is read."}, {"code": "local   all             all                                     peer", "note": "Line 123, the rule lesson 3 met. `local` is the socket, `all` and `all` match any database and any role, and `peer` asks the kernel which user is at the other end and admits them only as the role of the same name. Nothing is typed: the operating system has already vouched for you."}, {"code": "host    all             all             127.0.0.1/32            scram-sha-256", "note": "Line 125. `host` is TCP, encrypted or not, from the single address `127.0.0.1`, since `/32` keeps all 32 bits. `scram-sha-256` asks for the role's password through a challenge, so the password never crosses the connection. A role with no password, like yours, can never pass it."}, {"code": "host    all             all             ::1/128                 scram-sha-256", "note": "Line 127, the same rule for IPv6's loopback address. `-h localhost` may arrive on either, and a machine that answers on both needs both lines."}, {"code": "local   replication     all                                     peer\nhost    replication     all             127.0.0.1/32            scram-sha-256\nhost    replication     all             ::1/128                 scram-sha-256", "note": "Lines 130 to 132. `replication` here is not a database name but a keyword for the connections a standby makes to copy the write-ahead log, which db-reliability lesson 11 sets up. `all` in the database column does not include them."}]}
```

**There is no falling through.** A connection that matches a line and then fails its method is
refused; the server does not try the next line. And a connection no line matches is refused too,
with a message of its own. Those two refusals look alike to the person connecting and are
different problems, as the rest of this section shows.

Other methods exist and are worth recognising. `trust` admits anybody who matches without
asking anything, and has no place on a server anybody else can reach. `reject` refuses whoever
matches, which is useful above a broader line to carve out an exception. `md5` is the older
password method that `scram-sha-256` replaced. `cert` asks for a client certificate. Lesson 11
returns to `peer` with a map that lets an operating-system user log in as a role of another
name.

## The server's own reading of the file

The view `pg_hba_file_rules` is the file as the server parses it, and it has an `error`
column like `pg_file_settings`:

```
ana@db:~$ psql
ana=# SELECT line_number, type, database, user_name, address, auth_method
ana-#   FROM pg_hba_file_rules;
 line_number | type  |   database    | user_name  |  address  |  auth_method  
-------------+-------+---------------+------------+-----------+---------------
         118 | local | {all}         | {postgres} |           | peer
         123 | local | {all}         | {all}      |           | peer
         125 | host  | {all}         | {all}      | 127.0.0.1 | scram-sha-256
         127 | host  | {all}         | {all}      | ::1       | scram-sha-256
         130 | local | {replication} | {all}      |           | peer
         131 | host  | {replication} | {all}      | 127.0.0.1 | scram-sha-256
         132 | host  | {replication} | {all}      | ::1       | scram-sha-256
(7 rows)

ana=# \q
```

It reads the file on disk, not the rules in force, so it is the check to run **after an edit and
before the reload**. A line with a typo appears there with its error, and a reload with a broken
`pg_hba.conf` keeps the old rules, just as a broken `postgresql.conf` keeps the old values.

## A refusal, and what only the log knows

Connect over TCP with a password that is wrong. `PGPASSWORD` hands `psql` a password without a prompt. That is fine for a password meant to fail,
and a habit to avoid with a real one, which would end up in your shell history; lesson 11 sets
real passwords the right way.

```
ana@db:~$ PGPASSWORD=not-my-password psql -h 127.0.0.1
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
ana@db:~$ sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:42:07.082 -03 [366] ana@ana FATAL:  password authentication failed for user "ana"
2026-10-10 04:42:07.082 -03 [366] ana@ana DETAIL:  User "ana" has no password assigned.
	Connection matched file "/etc/postgresql/16/main/pg_hba.conf" line 125: "host    all             all             127.0.0.1/32            scram-sha-256"
```

`psql` tried twice, once with encryption and once without, because `ssl = on` in the server's
file and the client's default is to prefer encryption and settle for none; both attempts met the
same rule. Then the log says what the client was not told: **the real reason, and the line that
matched**. A client that types a wrong password and a client whose role has no password at all
get the same sentence on purpose, so that a stranger learns nothing about which roles exist. The
administrator reads the `DETAIL`.

## Changing a line

Open the file with `sudo nano /etc/postgresql/16/main/pg_hba.conf` and change line 125 so that
TCP from this machine reaches only the `shop` database: replace the first `all` with `shop`,
keeping the columns lined up. `pg_hba.conf` is read at a reload like the rest of the configuration, so reload, then try both
databases:

```
ana@db:~$ sudo sed -n 125p /etc/postgresql/16/main/pg_hba.conf
host    shop            all             127.0.0.1/32            scram-sha-256
ana@db:~$ sudo systemctl reload postgresql
ana@db:~$ PGPASSWORD=not-my-password psql -h 127.0.0.1
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "ana", database "ana", SSL encryption
connection to server at "127.0.0.1", port 5432 failed: FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "ana", database "ana", no encryption
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:42:08.528 -03 [394] ana@ana FATAL:  no pg_hba.conf entry for host "127.0.0.1", user "ana", database "ana", no encryption
ana@db:~$ PGPASSWORD=not-my-password psql -h 127.0.0.1 shop
psql: error: connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
connection to server at "127.0.0.1", port 5432 failed: FATAL:  password authentication failed for user "ana"
```

The connection to `ana` now matches no line at all: `no pg_hba.conf entry`, followed by the
four things the server compared, **the address, the role, the database and the encryption**. Each
is a column of the file, and reading the message against the file shows which one missed. The
connection to `shop` still matches line 125, gets as far as the password, and fails there.

That message is the one you will meet most as an administrator. An application on a new machine,
a role nobody added, a database renamed: each produces it, and the four values in it say which
line is missing.

**Changes apply to new connections only.** Sessions already open stay connected with whatever
rule admitted them. Put the line back as it was, and reload again:

```
ana@db:~$ sudo sed -n 125p /etc/postgresql/16/main/pg_hba.conf
host    shop            all             127.0.0.1/32            scram-sha-256
ana@db:~$ sudo systemctl reload postgresql
```

**Order is the thing to check when a new line seems to do nothing.** A line added at the bottom
of the file, below a broader rule that already matches the same connections, is never reached:
the broader rule decides first. Narrow rules go above wide ones, and `reject` lines above the
rule they make an exception to.
