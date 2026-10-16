---
title: Several hosts in one connection string
version: 1
---

`libpq`, the library behind `psql` and most PostgreSQL drivers, accepts a **list** of hosts and ports,
and a condition the server it keeps must meet. It tries them in order and settles on the first one
that qualifies:

```
ana@vm:~$ psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=read-write' -XAt -c 'SELECT inet_server_port()'
5441
ana@vm:~$ psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=standby' -XAt -c 'SELECT inet_server_port()'
5442
```

With `target_session_attrs=read-write` it skipped nothing, because `pg1` on 5441 is the primary and
first in the list. With `standby` it passed over 5441 and kept `pg2`. After a failover, the same
string, unchanged, reaches the new primary; the last section shows it doing that.

This is the cheapest of the four: nothing to install and nothing that can fail in between. Its costs
are on the application's side. Every application's configuration lists every server, so adding one is
a change to all of them; each new connection may try a dead host first and wait out its connect
timeout, so `connect_timeout` should be short; and drivers that do not use `libpq` need their own
support for it. The JDBC driver has it (`targetServerType=primary`); many others do too, under
other names.
