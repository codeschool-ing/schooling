---
title: PgBouncer between the application and the server
version: 1
---

**PgBouncer** is a small program that accepts connections as if it were PostgreSQL and passes their
work to a **pool** of real server connections, much fewer of them, which it keeps open. Install it:

```sh
sudo apt install -y pgbouncer
```

The package starts one PgBouncer as a service, on port 6432, with a configuration in
`/etc/pgbouncer`. This lesson leaves that one alone and runs its own, as you, on port **6433**, with
everything in `~/pgbouncer`, so that you can change it and restart it without `sudo`.

The application gets a role of its own, `shop_app`, with a password, the rights it needs on `shop`, and
a database `bench` of its own for `pgbench`:

```
shop=# CREATE ROLE shop_app LOGIN PASSWORD 'app-pass-1';
CREATE ROLE

shop=# GRANT SELECT, INSERT, UPDATE ON customers, orders TO shop_app;
GRANT

shop=# GRANT USAGE ON SEQUENCE orders_id_seq TO shop_app;
GRANT

shop=# ALTER DATABASE bench OWNER TO shop_app;
ALTER DATABASE
ana@vm:~$ echo '127.0.0.1:*:*:shop_app:app-pass-1' >> ~/.pgpass && chmod 600 ~/.pgpass
ana@vm:~$ dropdb bench && createdb -O shop_app bench && pgbench -q -i -s 10 -h 127.0.0.1 -U shop_app bench > /dev/null 2>&1
```

PgBouncer checks passwords itself, before it has a server connection to ask, so it needs each user's
password in its own file. With SCRAM, which is how PostgreSQL 16 stores passwords, the file holds the
same **SCRAM secret** the server keeps, never the password; copy it from the server:

```
ana@vm:~$ mkdir -p ~/pgbouncer
ana@vm:~$ psql -XAt shop -c "SELECT format('\"%s\" \"%s\"', rolname, rolpassword) FROM pg_authid WHERE rolname = 'shop_app'" > ~/pgbouncer/userlist.txt
ana@vm:~$ cut -c1-60 ~/pgbouncer/userlist.txt
"shop_app" "SCRAM-SHA-256$4096:QldR6MRSe4CH6F47p/P/3w==$9BXx
```

Then the configuration, saved as `~/pgbouncer/pgbouncer.ini`:

```schooling-example
{"language": "ini", "file": "pgbouncer.ini", "parts": [{"code": "[databases]\nshop = host=127.0.0.1 port=5432 dbname=shop pool_size=1\nbench = host=127.0.0.1 port=5432 dbname=bench\n", "note": "One line per database PgBouncer offers, and where it really is. `shop` is limited to a pool of one server connection, so that the last section can show what a pool does with a session's settings."}, {"code": "[pgbouncer]\nlisten_addr = 127.0.0.1\nlisten_port = 6433\nunix_socket_dir =", "note": "Where it listens: this machine only, on its own port, next to the package's 6432."}, {"code": "auth_type = scram-sha-256\nauth_file = /home/ana/pgbouncer/userlist.txt\nadmin_users = shop_app", "note": "Passwords are checked against the file you just wrote. `admin_users` may connect to the special database `pgbouncer` and ask about the pools."}, {"code": "pool_mode = transaction\nmax_client_conn = 500\ndefault_pool_size = 20", "note": "The pooling mode, the subject of the rest of this lesson, and the sizes: up to 500 clients, sharing at most 20 server connections per database and user."}, {"code": "logfile = /home/ana/pgbouncer/pgbouncer.log\npidfile = /home/ana/pgbouncer/pgbouncer.pid", "note": "Its own log and process-ID file, in the same directory."}]}
```

Change `ana` to your user name in the three paths. Start it in the background with `-d`, and connect
through it exactly as to a server, only on its port:

```
ana@vm:~$ pgbouncer -d ~/pgbouncer/pgbouncer.ini
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app -XAt shop -c "SELECT count(*) FROM orders"
50000
```
