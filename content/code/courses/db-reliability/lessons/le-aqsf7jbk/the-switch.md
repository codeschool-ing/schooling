---
title: What the application sees during a switch
version: 1
---

A stand-in for an application: one order a second, each on a new connection through HAProxy's port
5000, for forty seconds. Save it as `orders.sh` and make it executable:

```schooling-example
{"language": "sh", "file": "orders.sh", "parts": [{"code": "#!/bin/sh\n# orders.sh: one order a second through HAProxy, for 40 seconds\nfor i in $(seq 1 40); do\n  if port=$(psql -h 127.0.0.1 -p 5000 -U postgres -XAtq shop -c \"\n      INSERT INTO orders (customer_id, total_cents, placed_at)\n      VALUES ($i, 1000 + $i, now()) RETURNING inet_server_port()\" 2>/dev/null)\n  then\n    echo \"$(date +%T) ok on $port\"\n  else\n    echo \"$(date +%T) FAILED\"\n  fi\n  sleep 1\ndone", "note": "A stand-in for an application: one order a second, each on a new connection through port 5000, for forty seconds. Every line says whether it worked, when, and which server took it."}]}
```

Start two things in the background: a long-lived connection through port 5000 that asks which server
it is on, sleeps thirty seconds and asks again, and `orders.sh`. Then, while both run, move the leader
from `pg1` to `pg2`:

```
ana@vm:~$ psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c 'SELECT inet_server_port()' -c 'SELECT pg_sleep(30)' -c 'SELECT inet_server_port()' > held.log 2>&1 &
ana@vm:~$ ./orders.sh > orders.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml switchover --leader pg1 --candidate pg2 --force > /dev/null 2>&1
```

When it has all finished, the orders:

```
ana@vm:~$ cat orders.log
02:17:30 ok on 5441
02:17:31 ok on 5441
02:17:32 ok on 5441
02:17:33 ok on 5441
02:17:34 ok on 5441
02:17:35 ok on 5441
02:17:36 ok on 5441
02:17:37 ok on 5441
02:17:38 ok on 5441
02:17:42 FAILED
02:17:43 FAILED
02:17:44 ok on 5442
02:17:45 ok on 5442
02:17:46 ok on 5442
02:17:47 ok on 5442
02:17:49 ok on 5442
02:17:50 ok on 5442
02:17:51 ok on 5442
02:17:52 ok on 5442
02:17:53 ok on 5442
02:17:54 ok on 5442
02:17:55 ok on 5442
02:17:56 ok on 5442
02:17:57 ok on 5442
02:17:58 ok on 5442
02:17:59 ok on 5442
02:18:00 ok on 5442
02:18:01 ok on 5442
02:18:02 ok on 5442
02:18:03 ok on 5442
02:18:04 ok on 5442
02:18:05 ok on 5442
02:18:07 ok on 5442
02:18:08 ok on 5442
02:18:09 ok on 5442
02:18:10 ok on 5442
02:18:11 ok on 5442
02:18:12 ok on 5442
02:18:13 ok on 5442
02:18:14 ok on 5442
```

Nine orders on `pg1`, then **two failures**, then orders on `pg2` until the end. Between the last order
on 5441 at 02:17:38 and the first on 5442 at 02:17:44 the shop took nothing for about **six seconds**:
Patroni stopping `pg1` cleanly, promoting `pg2`, and HAProxy's checks needing two good answers in a
row, two seconds apart, before sending anybody to it. The attempt after 02:17:38 hung in the middle of
the switch and failed at 02:17:42. That is a **switchover**, the gentle kind; a
failover adds lesson 16's `ttl` on top.

And the long-lived connection:

```
ana@vm:~$ cat held.log
5441
FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
connection to server was lost
```

It answered `5441` and was then **terminated**, `pg_sleep` and all, when `pg1` was stopped for the
switch. Its third statement never ran. No proxy, address or connection string can carry an open
connection from one server to another, because the session itself, its transaction and its settings,
lived in a process on the old primary.

## What the application has to do

The proxy did its part: new connections went to the right place within seconds. Everything else is in
the application:

- **Treat a broken connection as expected**, during a failover or a switchover, and reconnect rather
  than crash or show an error page.
- **Retry the transaction, not the statement**, and only if it is safe to: an order that failed with
  "connection lost" may or may not have been committed, which is lesson 12's lesson again. An order
  table with a unique key supplied by the application (an order number generated before the insert)
  makes a retry that duplicates nothing.
- **Wait a little between retries**, because the first seconds after a switch are when the new primary
  is least ready and every client is reconnecting at once.

The two failures above are what `orders.sh` does without any of that: it reports them and moves on.
A shop that does the same loses those two orders.

Afterwards, HAProxy and the connection string both point at `pg2`:

```
ana@vm:~$ curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^primary,pg'
primary,pg1,DOWN
primary,pg2,UP
primary,pg3,DOWN
ana@vm:~$ psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=read-write' -XAt -c 'SELECT inet_server_port()'
5442
```
