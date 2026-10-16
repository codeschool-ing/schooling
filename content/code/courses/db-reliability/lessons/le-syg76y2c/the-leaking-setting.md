---
title: A setting that outlives its client
version: 1
---

Transaction mode gives the server connection back after every transaction, so the next transaction
from the same client can run on a different connection, and a different client's can run on this
one. Everything a client sets **for its session** stays with the server connection, not with the
client. `shop` was given a pool of one connection, which makes the effect certain rather than likely.
Three separate clients, one after the other:

```
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SET statement_timeout = '1ms'"
SET
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"
 statement_timeout 
-------------------
 1ms
(1 row)

ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SELECT count(*) FROM orders"
ERROR:  canceling statement due to statement timeout
```

The first client set a one-millisecond `statement_timeout` for its session and left. The second
client, which set nothing, **found it**. The third ran an ordinary count and was cancelled by a
timeout it never asked for. In production, with a pool of twenty and a thousand clients, this is a
bug that appears in one request out of some hundreds, on whichever connection the setting landed,
and is never reproducible on a developer's machine.

What leaks in transaction mode is anything that belongs to the session rather than the transaction:

- `SET` without `LOCAL`: timeouts, `search_path`, the time zone;
- prepared statements made with SQL `PREPARE`, and session-level advisory locks;
- temporary tables, and `LISTEN`.

The cure for settings is `SET LOCAL`, which lasts until the end of the transaction:

```
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SET statement_timeout = 0"
SET
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "BEGIN" -c "SET LOCAL statement_timeout = '1ms'" -c "SHOW statement_timeout" -c "COMMIT"
BEGIN
SET
 statement_timeout 
-------------------
 1ms
(1 row)

COMMIT
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"
 statement_timeout 
-------------------
 0
(1 row)
```

Inside the transaction the timeout applied; after `COMMIT`, the next client sees `0`, the default
the first command of this block put back. An application behind a transaction-mode pool sets
everything it needs with `SET LOCAL` inside each transaction, or once per user in the database with
`ALTER ROLE … SET`, which every new connection picks up.
