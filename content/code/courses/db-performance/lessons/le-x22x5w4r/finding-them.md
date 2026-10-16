---
title: Finding the oldest transactions
version: 1
---

The timeouts end what gets past them. Before you set them, and on any server where somebody else
set them, you need the other half: a query that answers **who is holding the horizon right now, and
for how long**. It is one `SELECT` on `pg_stat_activity`, worth keeping in a file:

```sh
cat > ~/oldest.sql <<'SQL'
-- oldest.sql: every session holding the horizon back, oldest first.
SELECT pid, state, backend_xid AS xid, backend_xmin AS xmin,
       greatest(age(backend_xid), age(backend_xmin)) AS xid_age,
       date_trunc('second', now() - xact_start) AS open_for,
       left(query, 40) AS last_query
FROM pg_stat_activity
WHERE (backend_xid IS NOT NULL OR backend_xmin IS NOT NULL)
  AND pid <> pg_backend_pid()
ORDER BY xid_age DESC;
SQL
```

Two columns hold the horizon. **`backend_xid`** is the session's own transaction number, which a
transaction only gets when it writes; **`backend_xmin`** is the oldest snapshot it is using. `age()`
turns either into "how many transactions ago", which is the unit that matters: a horizon is not old
because of the clock, it is old because of how much has been written since. `open_for` is the
clock's view, from `xact_start`, and `last_query` is the last statement the session sent — for an
idle session, the one it finished, not one it is running. The `WHERE` drops your own session, which
always has a snapshot while it runs the query.

## Four sessions, three suspects

To see each kind at once, open four more terminals and leave each one in a different state:

1. `BEGIN;` and `SELECT count(*) FROM sellers;` — a transaction at the default level that has only
   read;
2. `BEGIN;` and `UPDATE sellers SET name = 'Seller 2 (verified)' WHERE id = 2;` — a transaction that
   has written;
3. `BEGIN ISOLATION LEVEL REPEATABLE READ;` and `SELECT count(*) FROM sellers;` — Session A's kind;
4. `SELECT pg_sleep(40);` — a statement that is still running, standing in for a long report.

Run the robot from section 03 for a few seconds so that some transactions go by, then the file:

```
market=# \i oldest.sql
 pid  |        state        |   xid   |  xmin   | xid_age | open_for |                last_query                
------+---------------------+---------+---------+---------+----------+------------------------------------------
  963 | idle in transaction | 1380441 |         |   30733 | 00:00:07 | UPDATE sellers SET name = 'Seller 2 (ver
  988 | idle in transaction |         | 1380441 |   30733 | 00:00:06 | SELECT count(*) FROM sellers;
 1002 | active              |         | 1380441 |   30733 | 00:00:06 | SELECT pg_sleep(40)
(3 rows)

Time: 3.701 ms
```

**Three rows for four sessions**, and the missing one is the first: the `READ COMMITTED`
transaction that only read holds nothing, as section 02 said. The other three are all here, and
they are the three things to look for on a real server.

- The **writer** has a transaction number of its own, `1380441`, and no snapshot while it is idle.
  Everything written after it waits on it.
- The **`REPEATABLE READ`** session has no number of its own, because it has not written, and a
  snapshot that started at the same point.
- The **running statement** is `active`, not idle, and holds its snapshot for as long as it runs.
  `idle_in_transaction_session_timeout` would never touch it; `statement_timeout` would.

All three are `30733` transactions old, the robot's few seconds of work, which is why `xid_age` is
the column to sort by and to alert on: **it grows with the damage**, while `open_for` grows with the
clock whether anything is being written or not.

## Ending one

Once a session is found, the fix is to end its transaction: ask whoever owns it, or cancel or
terminate it from the server. `pg_cancel_backend` and `pg_terminate_backend`, and the difference
between them, are lesson 13's subject; here the order matters more than the tool. First the
**writer**, because it holds locks as well as the horizon. Then the oldest snapshot. Then look
again, because the next oldest becomes the horizon the moment the first one goes, and it may be only
a little younger.

## Two holders that are not sessions

Not every horizon belongs to a connection, and those that do not are the easy ones to miss, because
`pg_stat_activity` has no row for them:

```
market=# SELECT gid, prepared, owner FROM pg_prepared_xacts;
 gid | prepared | owner 
-----+----------+-------
(0 rows)

Time: 2.138 ms

market=# SELECT slot_name, xmin, catalog_xmin FROM pg_replication_slots;
 slot_name | xmin | catalog_xmin 
-----------+------+--------------
(0 rows)

Time: 0.866 ms

market=# BEGIN;
BEGIN
Time: 0.185 ms

market=*# PREPARE TRANSACTION 'pay-1';
ERROR:  prepared transactions are disabled
HINT:  Set max_prepared_transactions to a nonzero value.
Time: 0.966 ms
```

- **Prepared transactions.** `PREPARE TRANSACTION` is the first half of a two-phase commit: the
  transaction is finished from the client's point of view and kept by the server, with its locks and
  its horizon, until somebody runs `COMMIT PREPARED` or `ROLLBACK PREPARED` — after any restart, and
  however long it takes. A coordinator that crashes between the two halves leaves one behind that
  nobody remembers. They are **disabled by default**, as the error says, with `max_prepared_transactions`
  at 0, and an empty `pg_prepared_xacts` is what you want to see on a server where they are enabled.
- **Replication slots.** A slot keeps what a replica or a change-data consumer still needs, and its
  `xmin` and `catalog_xmin` columns are a horizon like any other. A slot whose consumer has gone away
  holds the horizon, and the WAL, forever. Setting up replication and slots is `db-reliability`'s
  subject; here, an empty list is the healthy answer.

A replica can also hold the primary's horizon through `hot_standby_feedback`, which reports the
replica's oldest snapshot back so that its long reports are not cancelled; lesson 20 meets that
trade from the replica's side.

So the full check is three queries — `~/oldest.sql`, `pg_prepared_xacts` and `pg_replication_slots`
— and the number to watch on all of them is the age in transactions. Finish the four sessions,
`ROLLBACK` in the second so that seller 2 keeps its name, and close every terminal on `market`. The
pricing robot changed `products` all through this lesson, so put the database back as lesson 16
starts:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 18.503 ms
CREATE INDEX
Time: 1162.979 ms (00:01.163)
```
