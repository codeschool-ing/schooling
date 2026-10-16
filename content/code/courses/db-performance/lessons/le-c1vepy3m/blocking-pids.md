---
title: pg_blocking_pids, and the session at the root
version: 1
---

`pg_blocking_pids(pid)` takes one session's process id and returns the ids of the sessions it is
waiting for, as an array. It applies the server's own rules: the conflict matrix of lesson 12 for
table locks, the transaction waits of the previous section for rows, and the queue of lesson 12
section 04, where a session waits for someone who is only waiting too. **It answers the question
`pg_locks` makes you work out, and it answers it the way the server decided it.** An empty array
means the session is waiting for nobody.

## Who is waiting, and for whom

The sessions that are waiting for a lock right now are the ones whose `wait_event_type` in
`pg_stat_activity` is `Lock`. In window D:

```
market=# SELECT pid, pg_blocking_pids(pid) FROM pg_stat_activity WHERE wait_event_type = 'Lock';
 pid  | pg_blocking_pids 
------+------------------
 5794 | {5792}
 5796 | {5794}
(2 rows)

Time: 2.722 ms
```

Window B (5794) waits for window A (5792), and window C (5796) waits for window B. Two rows, and the
whole shape of the problem is already there.

## The view to keep

That answer names the waiters. To act, you need the same list with what each session is doing and
for how long, **including the sessions that are not waiting**, because the one at the bottom of the
trouble is usually one of those. This file reads everything from `pg_stat_activity`, the view with
one row per connection, and adds `pg_blocking_pids` to each row:

```sh
cat > ~/blocked.sql <<'SQL'
-- blocked.sql: every session on this database, oldest transaction first,
-- with the sessions it is waiting for and what it is doing.
SELECT pid,
       pg_blocking_pids(pid) AS blocked_by,
       state,
       wait_event_type || ':' || wait_event AS waiting_on,
       date_trunc('second', now() - xact_start) AS in_transaction,
       left(query, 45) AS last_query
FROM pg_stat_activity
WHERE datname = current_database() AND pid <> pg_backend_pid()
ORDER BY xact_start;
SQL
```

Save it, and run it in window D with `\i`, which reads a file into the session as if you had
typed it:

```
market=# \i ~/blocked.sql
 pid  | blocked_by |        state        |     waiting_on     | in_transaction |                  last_query                   
------+------------+---------------------+--------------------+----------------+-----------------------------------------------
 5792 | {}         | idle in transaction | Client:ClientRead  | 00:00:33       | UPDATE orders SET status = 'shipped' WHERE id
 5794 | {5792}     | active              | Lock:transactionid | 00:00:31       | UPDATE orders SET status = 'shipped' WHERE id
 5796 | {5794}     | active              | Lock:transactionid | 00:00:26       | UPDATE orders SET status = 'cancelled' WHERE 
(3 rows)

Time: 2.821 ms
```

Five columns tell the story, one session per row.

**`blocked_by`** is the function above. Read it as arrows: 5794 points at 5792, 5796 points at
5794.

**`state`** is what the connection is doing. `active` means a statement is running, and here both
active sessions are running a statement that is only waiting. **`idle in transaction`** means the
connection has a transaction open and is not running anything: the server is waiting for the
client to send the next statement. Window A is that: the session doing nothing, with everybody else stuck behind it.

**`waiting_on`** joins `wait_event_type` and `wait_event`. `Lock:transactionid` is the
`ShareLock on transaction` of the previous section, seen from here. `Client:ClientRead` is a
backend waiting for its client to say something, which for an idle-in-transaction session is the
whole explanation: **the server is not slow, the application has stopped talking.**

**`in_transaction`** is how long ago the session's transaction began, from `xact_start`. The
oldest open transaction is the first row, because the file sorts by it, and on a real server it is
the first row to look at for a reason lesson 15 spends a whole lesson on.

**`last_query`** is the most recent statement the session sent, cut to 45 characters here. For an
active session it is the statement running now. For an idle one it is the **last** statement it ran,
which is the best clue you have about which part of the application left the transaction open: the
`UPDATE` of order 1, sent 33 seconds ago and never followed by a `COMMIT`.

## What to read first

On a real server this view has dozens or hundreds of rows. Three habits make it fast:

- **Look at `blocked_by` before anything else.** Most rows are `{}`; the ones that are not are the
  problem, and the pids inside the braces are where to look next.
- **Follow a pid that appears in somebody's `blocked_by` to its own row.** If its own `blocked_by`
  is `{}`, you have found a session that blocks and does not wait, and it is a candidate for the
  root.
- **Distrust the session that is doing nothing.** A long-running `active` query is visible to
  everyone; an `idle in transaction` session for 33 seconds, or for three hours, looks harmless on
  every dashboard that only shows running queries.

Two waiters are easy to follow by eye. The next section writes the query that follows a longer
chain for you.
