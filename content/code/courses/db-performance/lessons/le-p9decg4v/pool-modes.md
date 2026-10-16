---
title: Transaction or session pooling, and what breaks in between
version: 1
---

The line `pool_mode = transaction` decided when PgBouncer takes a server connection back from a
client. It has three possible values, and the difference between the first two is the whole
question of whether an application can use a pool without changing:

- **`session`**: a client keeps one server connection from connecting to disconnecting. Nothing
  about the client's view changes, and nothing is saved either: two hundred clients still need two
  hundred server connections. It helps only with the cost of connecting, when clients connect and
  disconnect often.
- **`transaction`**: a client holds a server connection for one transaction and gives it back at
  `COMMIT` or `ROLLBACK`; a statement outside a transaction is a transaction of its own. Two hundred
  clients share eight connections, which is section 04's result.
- **`statement`**: a connection is given back after every statement, so multi-statement
  transactions are refused. Rarely used.

Transaction mode is what makes a pool worth having, and its price is this: **a client's next
transaction may run on a different server connection**, and anything the client set up on the
connection, rather than inside a transaction, stays behind on the old one.

## A setting that goes to somebody else

Open two `psql` sessions through PgBouncer, `psql -h 127.0.0.1 -p 6432 market` in two terminals.
In **Session A**, set a statement timeout of one second, the way an application might at start-up,
and ask which server process answered:

```
market=# SET statement_timeout = '1s';
SET
Time: 0.954 ms

market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8617
(1 row)

Time: 0.878 ms
```

Now in **Session B**, open a transaction and ask the same question:

```
market=# BEGIN;
BEGIN
Time: 0.685 ms

market=*# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8617
(1 row)

Time: 0.941 ms
```

**8617**: Session B was given the server connection Session A used a moment ago, because it was
idle and PgBouncer reuses the most recently returned one first. Leave B's transaction open and go
back to A:

```
market=# SHOW statement_timeout;
 statement_timeout 
-------------------
 0
(1 row)

Time: 0.881 ms

market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8753
(1 row)

Time: 1.122 ms
```

Session A's `statement_timeout` is **`0`**, as if it had never been set, and its process is a
different one, 8753, because its old connection is inside B's transaction. Now commit in B and look
at the setting there:

```
market=*# COMMIT;
COMMIT
Time: 0.797 ms

market=# SHOW statement_timeout;
 statement_timeout 
-------------------
 1s
(1 row)

Time: 0.738 ms

market=# SELECT pg_backend_pid();
 pg_backend_pid 
----------------
           8617
(1 row)

Time: 0.715 ms
```

Session B never set anything, and its timeout is **`1s`**. Its next transaction ran on 8617 again,
the connection that still carries Session A's `SET`. So the setting was lost by the client that
made it and **given to a client that did not ask for it** — which, for `statement_timeout`, is a
stranger's report cancelled after one second with no change in its own code.

The rule that follows is simple to state: **in transaction mode, set nothing on the session.**
Settings belong in the role or the database (`ALTER ROLE … SET`, as lesson 15 did for timeouts), or
inside the transaction with `SET LOCAL`, which ends with it.

## The same trap, three more times

Everything that lives on a session rather than in a transaction has the same problem:

- **Session-level advisory locks.** `pg_advisory_lock` (lesson 12) is held by the server connection
  until it is released or the connection closes. Taken through a transaction pool, it stays on a
  connection the client no longer holds, and the client's `pg_advisory_unlock` may run somewhere
  else and release nothing. `pg_advisory_xact_lock`, which ends with the transaction, is the one
  that works.
- **`LISTEN`.** A listening connection receives notifications whenever they arrive, between
  transactions. In transaction mode the client is not attached to any connection between
  transactions, so a listener belongs on a direct connection or a session-mode pool.
- **Temporary tables and `WITH HOLD` cursors**, which outlive the transaction that made them, for
  the same reason.

## Prepared statements

Drivers prepare statements to save parsing: they send the query once under a name and afterwards
only the name and the parameters. The name lives on the **server connection**, so in a transaction
pool the next execution can land on a connection that never saw it. `pgbench -M prepared` behaves
like such a driver:

```
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -M prepared -c 4 -T 5 -f customer-orders.sql market 2>&1 | grep -E "error|processed" | head -3
pgbench: error: ERROR:  prepared statement "P_0" already exists
pgbench: error: ERROR:  prepared statement "P_0" already exists
pgbench: error: client 0 script 0 aborted in command 1 query 0: ERROR:  prepared statement "P_0" does not exist
```

`prepared statement "P_0" already exists` on one connection, `does not exist` on others: clients
preparing on connections where somebody else had prepared the same name, and executing on ones where
nobody had. PgBouncer 1.21 added a fix, and 1.22, the version Ubuntu installs, has it: with
**`max_prepared_statements`** above zero, PgBouncer keeps track of what each client prepared and
prepares it again, under its own name, on whatever connection the client is given. Add one line
under `max_client_conn` in the file, then reload:

```ini
max_prepared_statements = 100
```

```
ana@vm:~$ sudo systemctl reload pgbouncer
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -M prepared -c 4 -T 5 -f customer-orders.sql market 2>&1 | grep -E "error|processed|^tps"
number of transactions actually processed: 86764
tps = 17414.583459 (without initial connection time)
```

**17415 transactions a second** and no errors. Two limits remain. It covers statements prepared
through the protocol, which is what drivers do, and not the SQL `PREPARE` command typed as text. And
`100` is a cap on how many it keeps track of, so a client that prepares more distinct statements than
that has older ones prepared again as it goes.
