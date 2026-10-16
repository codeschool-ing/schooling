---
title: Pooling, in brief
version: 1
---

The last section found a connection holding too much for too long. The other common case is an
application opening too many, or opening a new one for every request, and the price of that is
the process start the first section described. `pgbench --connect` opens a fresh connection for
every transaction, so it measures exactly that price against the run from two sections ago:

```
ana@db:~$ pgbench --select-only --connect --client=4 --jobs=4 --time=15 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
starting vacuum...end.
transaction type: <builtin: select only>
scaling factor: 10
query mode: simple
number of clients: 4
number of threads: 4
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 10892
number of failed transactions: 0 (0.000%)
latency average = 5.509 ms
average connection time = 4.264 ms
tps = 726.068665 (including reconnection times)
```

**The same four clients and the same query managed 726 transactions a second instead of 90,620.**
Each connection took 4.264 ms to set up, for a lookup that took a fraction of a millisecond once
it was connected: a process started, authentication done, caches warmed from nothing, and all of
it thrown away a moment later.

## What a pooler does

A **connection pooler** sits between the application and the server and keeps a small number of
real server connections open. Clients connect to the pooler, which is cheap, and it lends them a
server connection for as long as they need one: for a whole session, or, in the mode that helps
most, for one transaction at a time. Hundreds of application connections then share a few dozen
backends, close to the number of processors that can run them, and the server never meets the
problems of the last three sections.

There are two places to put one. **The application's own driver** usually has a pool, and using it
fixes the connection-per-request pattern on its own. **A separate pooler**, PgBouncer being the
usual one, serves many application instances at once and is what lets `max_connections` stay
small while the number of clients grows. Choosing a mode, sizing the pool and what transaction
pooling breaks are `db-performance` lesson 16; running a pooler so that it is not itself the
thing that fails is `db-reliability` lesson 18.

## Putting everything back

```
ana@db:~$ dropdb bench
ana@db:~$ psql shop -c "REVOKE ALL ON customers, orders FROM app"
REVOKE
ana@db:~$ dropuser app
ana@db:~$ sudo userdel --remove app
userdel: app mail spool (/var/mail/app) not found
ana@db:~$ psql shop -Atc "SHOW max_connections"
100
```

**A role cannot be dropped while it still holds privileges**, which is why the `REVOKE` comes
first; lesson 13 has the general tool for that, `DROP OWNED`. The role's timeout went with it.
`userdel` only remarks that `app` never had a mailbox. `max_connections` is back to 100, as the
reset in the third section left it.
