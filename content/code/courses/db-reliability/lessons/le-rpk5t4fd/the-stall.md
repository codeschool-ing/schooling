---
title: When the standby is gone, the primary stops
version: 1
---

The guarantee "a confirmed commit is on two servers" has a consequence that is easy to read past:
**when there is no second server, nothing can be confirmed.** The primary does not fall back to
asynchronous on its own. It waits, for as long as it takes, and so does every application writing
to it. Stop the standby and try to place an order:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
ana@vm:~$ timeout 10 psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (21, 777777, now())"; echo "exit $?"
exit 124
shop=# SELECT state, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE wait_event = 'SyncRep';
 state  | wait_event_type | wait_event |                  query                   
--------+-----------------+------------+------------------------------------------
 active | IPC             | SyncRep    | INSERT INTO orders (customer_id, total_c
(1 row)

shop=# SELECT count(*) FROM orders WHERE total_cents = 777777;
 count 
-------
     0
(1 row)
```

`timeout` gave up after ten seconds and killed `psql`, which is what `exit 124` means; without it the
prompt would still be waiting now. From a second session the primary shows what it is doing: an
`INSERT` in state `active`, waiting on `SyncRep`. And the order is **not there**, `count` 0, although
the primary has already written it to its own log and flushed it. A transaction waiting for its
standby is invisible to everybody else until the wait ends.

## A timeout does not end the wait

The obvious defence is a statement timeout, so that no request waits more than three seconds:

```
ana@vm:~$ PGOPTIONS='-c statement_timeout=3s' timeout 10 psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (23, 888888, now())"; echo "exit $?"
exit 124
```

It waited the full ten seconds again, and its session is now a second `INSERT` waiting on `SyncRep`, beside the first. `statement_timeout` limits the statement, and the statement
had finished: what is left is the commit, and the commit waits outside it. Nothing the application
sets on its own connection bounds that wait.

## Cancelling it, and what the application is told

The wait ends in three ways: the standby comes back, somebody changes `synchronous_standby_names`,
or the waiting session is cancelled. Start one more order in the background, with its output going to
a file, and cancel every session waiting on `SyncRep`:

```
ana@vm:~$ psql shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (24, 999999, now())" > insert.log 2>&1 &
shop=# SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event = 'SyncRep';
 pg_cancel_backend 
-------------------
 t
 t
 t
(3 rows)

shop=# SELECT total_cents, count(*) FROM orders WHERE total_cents > 700000 GROUP BY 1 ORDER BY 1;
 total_cents | count 
-------------+-------
      777777 |     1
      888888 |     1
      999999 |     1
(3 rows)
ana@vm:~$ cat insert.log
WARNING:  canceling wait for synchronous replication due to user request
DETAIL:  The transaction has already committed locally, but might not have been replicated to the standby.
INSERT 0 1
```

Three cancelled, and **three orders in the table.** All three were committed on the primary before
they started waiting, and cancelling the wait cannot take back a commit; it can only stop waiting for
the standby. The application that stayed connected was told so, in a warning, and then
`INSERT 0 1`: **success, on a row that exists on one server only.** That is precisely the state
synchronous replication was configured to prevent, and the application's code most likely reads the
`INSERT 0 1` and ignores the warning. The two whose clients `timeout` had killed were told nothing at
all.

So the honest description of `synchronous_standby_names = 'standby1'` is not "every commit is on two
servers". It is **"every commit is on two servers, or the database stops taking writes"**: an outage of
the standby is an outage of the primary. One standby is a configuration that doubles the number of
machines whose failure stops the shop. The next section fixes that.
