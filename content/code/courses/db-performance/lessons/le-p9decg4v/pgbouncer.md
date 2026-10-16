---
title: PgBouncer in front of the server
version: 1
---

A **connection pool** sits between the clients and the server. Clients connect to it, as many as
they like, and it keeps a small number of real server connections open and lends them out: a client
that has something to run gets one, runs it, and gives it back. PgBouncer is the pool most
PostgreSQL deployments use, a single small process that speaks PostgreSQL's protocol on both sides,
so the application changes its port and nothing else. This section installs it, configures it for
the simplest honest local setup, and repeats the experiment the server refused in section 02.

## Installing

PgBouncer is in Ubuntu's archive:

```sh
sudo apt install -y pgbouncer
```

`apt` installs it as a service, running as the `postgres` operating-system user and reading
`/etc/pgbouncer/pgbouncer.ini`. Check what you got:

```
ana@vm:~$ pgbouncer --version
PgBouncer 1.22.0
libevent 2.1.12-stable
adns: c-ares 1.27.0
tls: OpenSSL 3.0.13 30 Jan 2024
systemd: yes
```

## The configuration, whole

The file `apt` wrote is long and almost entirely comments. Keep it, and replace it with the short
one below:

```sh
sudo cp -p /etc/pgbouncer/pgbouncer.ini /etc/pgbouncer/pgbouncer.ini.orig
```

`-p` keeps the file's owner, `postgres`, on the copy, which matters when it goes back at the end of
the lesson: a configuration file the service cannot read is a service that will not start. Then
open `/etc/pgbouncer/pgbouncer.ini` with `sudo nano` and make it exactly this:

```schooling-example
{"language": "ini", "file": "/etc/pgbouncer/pgbouncer.ini", "parts": [
 {"code": "[databases]\nmarket = host=127.0.0.1 port=5432 dbname=market\n", "note": "The databases clients may ask for, and where each one really is. A client asks PgBouncer for `market`, and PgBouncer connects to the server on port 5432 over TCP. TCP and not the socket, because PgBouncer runs as the `postgres` user, and the socket's peer authentication would log it in as that user instead of as you."},
 {"code": "[pgbouncer]\nlisten_addr = 127.0.0.1\nlisten_port = 6432\nunix_socket_dir = /var/run/postgresql\n", "note": "Where PgBouncer listens: this machine only, on port 6432, next to the server's 5432 rather than in its place. Moving an application onto the pool is changing its port."},
 {"code": "auth_type = scram-sha-256\nauth_file = /etc/pgbouncer/userlist.txt\nadmin_users = ana\n", "note": "Clients prove who they are with a password, checked against `userlist.txt`, which holds each role's SCRAM secret — the same secret the server stores, never the password itself. PgBouncer then reuses the client's proof to log in to the server as the same role. `admin_users` lets `ana` into PgBouncer's own console."},
 {"code": "pool_mode = transaction\ndefault_pool_size = 8\nmax_client_conn = 500\n", "note": "The three lines that make it a pool. A server connection is lent for one **transaction** at a time; there are at most **8** of them per database and role; and up to **500** clients may connect. Section 05 is about the first line, section 06 about the second."},
 {"code": "logfile = /var/log/postgresql/pgbouncer.log\npidfile = /var/run/postgresql/pgbouncer.pid", "note": "Where it writes its log and its process id: the two lines kept from the file `apt` wrote."}
]}
```

## A password, for a pool that has to check one

Until now `ana` has logged in without a password: `psql` connects through the socket, and the server
trusts the operating system's word for who is on the other end. PgBouncer is a separate program
talking over TCP, so it needs a real one. Give `ana` a password, `market-lab`, which is fine for a
machine nobody else can reach and wrong anywhere else (`\password` in `psql` asks for it without
writing it into your history):

```
market=# ALTER ROLE ana PASSWORD 'market-lab';
ALTER ROLE
Time: 5.691 ms
```

Write the SCRAM secret the server now holds into PgBouncer's list of users, and the password into
`~/.pgpass`, where `psql` and `pgbench` look for it so that you do not type it every time:

```sh
psql -XAt market -c "SELECT concat('\"', rolname, '\" \"', rolpassword, '\"') FROM pg_authid WHERE rolname = 'ana'" | sudo tee /etc/pgbouncer/userlist.txt > /dev/null
```

```sh
cat > ~/.pgpass <<'PW'
127.0.0.1:6432:*:ana:market-lab
PW
chmod 600 ~/.pgpass
```

The first line of `userlist.txt` is the role and its secret, both in double quotes. The secret starts
with the method and its iteration count, then salt and keys; here are its first forty characters:

```
ana@vm:~$ sudo cut -c1-40 /etc/pgbouncer/userlist.txt
"ana" "SCRAM-SHA-256$4096:lk1o3Pr6bDk1+M
```

## Starting it, and going through it

```
ana@vm:~$ sudo systemctl restart pgbouncer
ana@vm:~$ systemctl is-active pgbouncer
active
```

Now open `psql -h 127.0.0.1 -p 6432 market`: `-h` and `-p` send it to PgBouncer instead of the
server. Ask who you are and which port the **server** sees:

```
market=# SELECT current_user, inet_server_port(), pg_backend_pid();
 current_user | inet_server_port | pg_backend_pid 
--------------+------------------+----------------
 ana          |             5432 |           8617
(1 row)

Time: 1.459 ms
```

You are `ana`, and the server answered from port 5432: the query went through PgBouncer and arrived
as an ordinary connection. Nothing in the SQL changed.

## Two hundred clients

Section 03 stopped at ninety clients because the server takes no more. Straight to the server, two
hundred is refused as before:

```
ana@vm:~/workload$ pgbench -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market 2>&1 | head -4
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
pgbench: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  sorry, too many clients already
pgbench: error: could not create connection for client 24
```

Through PgBouncer, the same two hundred, while PgBouncer's console shows its pool in the middle of
the run:

```
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E "^(number of clients|number of transactions|latency average|tps)"
number of clients: 200
number of transactions actually processed: 25428
latency average = 149.040 ms
tps = 1341.920895 (without initial connection time)
```

```
pgbouncer=# SHOW POOLS;
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_waiting_cancel_req | sv_active | sv_active_cancel | sv_being_canceled | sv_idle | sv_used | sv_tested | sv_login | maxwait | maxwait_us |  pool_mode  
-----------+-----------+-----------+------------+----------------------+-----------------------+-----------+------------------+-------------------+---------+---------+-----------+----------+---------+------------+-------------
 market    | ana       |         8 |        192 |                    0 |                     0 |         8 |                0 |                 0 |       0 |       0 |         0 |        0 |       0 |     156374 | transaction
 pgbouncer | pgbouncer |         1 |          0 |                    0 |                     0 |         0 |                0 |                 0 |       0 |       0 |         0 |        0 |       0 |          0 | statement
(2 rows)

Time: 10.980 ms
```

**200 clients, 1342 transactions a second, none refused.** `SHOW POOLS` explains it: 8
clients active, **192 waiting**, and **8 server connections** active, the `default_pool_size`. The
server never saw more than eight clients from the pool, and its own count of connections to `market`
agrees:

```
market=# SELECT count(*) FROM pg_stat_activity WHERE datname = 'market';
 count 
-------
     9
(1 row)

Time: 3.541 ms
```

Nine: PgBouncer's eight and this `psql`. The waiting happened in PgBouncer, where a waiting client
costs a few kilobytes instead of a process, and the latency, 149 milliseconds on average, is
mostly that wait — the same wait section 03 measured at ninety clients, moved somewhere cheaper. A
pool does not make the server faster. It stops the clients beyond what the server can use from
costing anything while they wait.
