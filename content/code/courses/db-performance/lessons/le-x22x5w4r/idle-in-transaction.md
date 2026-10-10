---
title: Idle in transaction, and the timeouts that end it
version: 1
---

Session A was a person who opened a transaction and walked away. In production the same state is
almost always made by **code**, and it has a name of its own in `pg_stat_activity`: `idle in
transaction`. The connection is open, a transaction has begun, the last statement finished, and the
server is waiting for the next one, which the application is in no hurry to send.

## How applications get there

Three shapes cover most of what you will find:

- **Work in the middle of a transaction that is not database work.** `BEGIN`, update the order,
  call the payment provider and wait two seconds for it, write the result, `COMMIT`. Every purchase
  holds its transaction open for the length of an HTTP call to somebody else's server — and, while it
  is open, the row lock on the order as well, which lessons 12 and 13 are about.
- **A transaction that was never closed.** An error path that returns without `ROLLBACK`, a
  framework that opens a transaction for every request and a request that never finishes, a pool
  that hands a connection back with a transaction still open in it.
- **A person.** A `psql` or a graphical client left with `BEGIN` typed in it over lunch, or a client
  configured to turn off autocommit, so that the first `SELECT` of the morning opens a transaction
  that lasts until somebody disconnects.

The first is the one worth designing away: **do the slow outside work before the transaction or
after it**, and keep the transaction to the statements that must succeed or fail together. The
other two cannot be designed away, only limited, and PostgreSQL has a setting for each of them.

## `idle_in_transaction_session_timeout`

This setting ends a session that has sat idle inside a transaction for longer than it allows. It is
off by default, which is the value `0`. Set it to five seconds for one session, open a transaction,
read something, and then leave the terminal alone for six seconds before typing again:

```
market=# SHOW idle_in_transaction_session_timeout;
 idle_in_transaction_session_timeout 
-------------------------------------
 0
(1 row)

Time: 0.370 ms

market=# SET idle_in_transaction_session_timeout = '5s';
SET
Time: 0.213 ms

market=# BEGIN;
BEGIN
Time: 0.295 ms

market=*# SELECT count(*) FROM sellers;
 count 
-------
  1000
(1 row)

Time: 2.085 ms

market=*# SELECT count(*) FROM sellers;
FATAL:  terminating connection due to idle-in-transaction timeout
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
Time: 4.521 ms
```

The server waited five seconds, then **ended the whole session**, not only the transaction:
`FATAL`, and the connection is gone. `psql` noticed when it tried to send the next statement, and
reconnected on its own, which an application's driver may or may not do. The transaction was rolled
back, its locks released, and the horizon it held moved on.

That severity is the point and also the price. A session that ends with `FATAL` costs the
application an error and a reconnection, so the value is chosen against the longest idle gap a
**correct** transaction in the application ever has, with room to spare: long enough that only a
forgotten transaction reaches it, short enough that a forgotten one is ended before it has done much
damage. Minutes rather than seconds is the usual range, and the right number is a measurement of
your own application, not a default.

## `statement_timeout`, for the other half

A transaction that is busy rather than idle is not covered by that setting. A twenty-minute report
holds a snapshot just as long as an idle session does, and its state in `pg_stat_activity` is
`active`. `statement_timeout` cancels any single statement that runs longer than it allows:

```
market=# SET statement_timeout = '100ms';
SET
Time: 0.384 ms

market=# SELECT count(*) FROM order_lines WHERE quantity = 3;
ERROR:  canceling statement due to statement timeout
Time: 118.517 ms
```

This one is an `ERROR`, not a `FATAL`. The statement is cancelled, the session stays, and inside a
transaction the transaction is left failed until the client rolls it back. The count over
`order_lines` takes a couple of hundred milliseconds warm, so a limit of 100 cancelled it at
**118.5 milliseconds**.

Neither setting covers the other's case, and that is why there are two. PostgreSQL 17 adds a third,
`transaction_timeout`, which limits the whole transaction whatever it is doing; the server in this
course is version 16, which does not have it, so it was not run here.

## Where to set them

`SET` changes a setting for one session, which is right for an experiment and wrong for a defence,
because the sessions that need it are the ones nobody is looking at. Set them for **the database**,
or for **the role the application connects as**, so that every new session starts with them:

```
market=# ALTER DATABASE market SET idle_in_transaction_session_timeout = '1min';
ALTER DATABASE
Time: 3.226 ms
market=# \q
ana@vm:~$ psql market
market=# SHOW idle_in_transaction_session_timeout;
 idle_in_transaction_session_timeout 
-------------------------------------
 1min
(1 row)

Time: 0.463 ms
```

The `ALTER DATABASE` changes nothing for sessions already connected; the new one, after `\q` and
`psql market`, starts with the minute. `ALTER ROLE app SET …` does the same for one role. That is
the better place when the application, the migrations and the people reading data connect as
different roles and need different limits: a migration that rebuilds an index legitimately runs
for longer than any request should.

Setting it for the whole server in `postgresql.conf` works too, and it is usually too broad: the
same limit then applies to a migration, a maintenance job and an analyst's legitimate long query.
Put this one back before going on, so that it does not end the transactions the next section opens
on purpose:

```
market=# ALTER DATABASE market RESET idle_in_transaction_session_timeout;
ALTER DATABASE
Time: 5.641 ms
```
