---
title: Session, transaction, statement
version: 1
---

`pool_mode` decides when a client gives its server connection back:

| mode | the connection returns when | what breaks | how many clients 20 connections serve |
|---|---|---|---|
| `session` | the client disconnects | nothing | 20 at a time |
| `transaction` | each transaction ends | session state, as above | many, if transactions are short |
| `statement` | each statement ends | transactions of more than one statement | many, for autocommit-only workloads |

Switch the pool to `session` mode, which PgBouncer rereads on a `SIGHUP` without dropping anybody,
and repeat both tests:

```
ana@vm:~$ sed -i 's/^pool_mode = transaction/pool_mode = session/' ~/pgbouncer/pgbouncer.ini
ana@vm:~$ kill -HUP $(cat ~/pgbouncer/pgbouncer.pid)
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SET statement_timeout = '1ms'"
SET
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app shop -c "SHOW statement_timeout"
 statement_timeout 
-------------------
 0
(1 row)

ana@vm:~$ pgbench -c 120 -T 5 -n -h 127.0.0.1 -p 6433 -U shop_app bench > ~/bench.out 2>&1 &
ana@vm:~$ psql -h 127.0.0.1 -p 6433 -U shop_app pgbouncer -c "SHOW POOLS" | cut -c1-80 | head -n 4
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_wait
-----------+-----------+-----------+------------+----------------------+--------
 bench     | shop_app  |        20 |        100 |                    0 |        
 pgbouncer | pgbouncer |         1 |          0 |                    0 |        
ana@vm:~$ time psql -h 127.0.0.1 -p 6433 -U shop_app -XAt bench -c "SELECT 1"
1

real	0m1.982s
user	0m0.033s
sys	0m0.009s
```

The setting **did not leak**: in session mode PgBouncer runs `DISCARD ALL` on a server connection
before handing it to the next client, and the session belongs to one client for its whole life. And
the extra `SELECT 1` now waited **1.982 seconds** instead of 0.143: twenty `pgbench` clients each
held a connection for their whole five-second session, so the query waited for one of those sessions
to end, not for one transaction.

Session mode is safe and pools only **connections**, which still helps with the cost of starting a
process on every connect. Transaction mode pools **work**, and asks the application to keep its
session state inside transactions. Pick it deliberately, test the application against it before
production does, and remember that a failover drops every server connection in the pool: lesson
19 is about how the pool, and the application, find the new primary.
