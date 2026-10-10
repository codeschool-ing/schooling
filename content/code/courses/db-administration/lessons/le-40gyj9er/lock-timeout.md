---
title: Waiting for a lock, briefly
version: 1
---

You cannot always know what holds a table when you change it. **You can decide how long your change
is allowed to wait**, and that turns an outage into a failed attempt. `lock_timeout` is the
setting: a statement that has waited that long for a lock gives up with an error, leaves the queue,
and lets everything behind it through.

The same three terminals, with one difference: the second sets `lock_timeout` before its `ALTER`.

```
ana@db:~$ psql shop
shop=# BEGIN;
BEGIN

shop=*# SELECT count(*) FROM orders_live;
  count  
---------
 1000000
(1 row)
```

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SET lock_timeout = '2s';
SET
Time: 0.252 ms

shop=# ALTER TABLE orders_live ADD COLUMN source text;
ERROR:  canceling statement due to lock timeout
Time: 2000.671 ms (00:02.001)
```

```
ana@db:~$ psql shop
shop=# \timing on
Timing is on.

shop=# SELECT status FROM orders_live WHERE id = 1;
 status 
--------
 paid
(1 row)

Time: 1238.296 ms (00:01.238)
```

**The `ALTER` gave up after two seconds**, with `canceling statement due to lock timeout`, and the
`SELECT` in the third terminal ran the moment it left the queue. The third terminal still waited,
for part of those two seconds, and that is the price: `lock_timeout` does not stop the queue from
forming, it limits how long it lasts. Two seconds of slow pages is an incident nobody reports.
Twenty minutes is the one that wakes you.

**`lock_timeout` is not `statement_timeout`.** The first counts only the time spent waiting for a lock;
the second counts the whole statement, work included. **A rewrite that needs a minute of work and
gets its lock at once is fine under a two-second `lock_timeout`**, and would be killed by a
two-second `statement_timeout`.

## Trying again

A change that gave up has not happened, so something has to try it again. On a busy table the
lock is free most of the time, and an attempt a few seconds later usually gets it. Save this as
`retry-ddl.sh`:

```schooling-example
{"language": "bash", "file": "retry-ddl.sh", "parts": [{"code": "#!/usr/bin/env bash\n# retry-ddl.sh: one schema change, retried until it gets its lock quickly.\n# Run it with: bash retry-ddl.sh\nddl=\"ALTER TABLE orders_live ADD COLUMN source text\"", "note": "The change goes in a variable at the top, so the script is the same for every change you will ever make with it."}, {"code": "for attempt in 1 2 3 4 5; do\n  if PGOPTIONS='-c lock_timeout=2s' psql -X -q shop -c \"$ddl\"; then\n    echo \"attempt $attempt: done\"\n    exit 0\n  fi", "note": "`PGOPTIONS` sets `lock_timeout` for this one connection, so the `ALTER` waits in the queue for two seconds at most. `-X` skips your `.psqlrc` and `-q` keeps psql quiet, so the only lines are the error and the script's own."}, {"code": "  echo \"attempt $attempt: gave up the queue; trying again in 3 s\" >&2\n  sleep 3\ndone", "note": "Between attempts it waits longer than it queued. Whatever was blocked behind the `ALTER` runs in that gap, and the transaction holding the table may finish."}, {"code": "echo \"no luck after $attempt attempts; find what holds the lock\" >&2\nexit 1", "note": "Five failures in a row mean something holds the table for a long time. That is a question for `pg_stat_activity`, not for a sixth attempt."}]}
```

To see it work, hold the table in one terminal as before, run the script in another, and commit
the first terminal a few seconds later:

```
ana@db:~$ psql shop
shop=# BEGIN;
BEGIN

shop=*# SELECT count(*) FROM orders_live;
  count  
---------
 1000000
(1 row)

shop=*# COMMIT;
COMMIT
```

```
ana@db:~$ bash retry-ddl.sh
ERROR:  canceling statement due to lock timeout
attempt 1: gave up the queue; trying again in 3 s
ERROR:  canceling statement due to lock timeout
attempt 2: gave up the queue; trying again in 3 s
attempt 3: done
```

Two attempts gave up while the transaction was open; the next one, after the commit, got its lock
and the column was added. Nothing waited behind the `ALTER` for more than two seconds at any point.

**Every schema change on a live table goes through something like this**, whether it is this script,
a setting in the migration tool your application uses, or a `SET lock_timeout` at the top of a
migration file. The number is a judgement about the application: how long can a query wait before
somebody notices. Two to five seconds is common, and lesson 10's `idle_in_transaction_session_timeout`
is the setting that stops the forgotten transaction from holding the table in the first place.
