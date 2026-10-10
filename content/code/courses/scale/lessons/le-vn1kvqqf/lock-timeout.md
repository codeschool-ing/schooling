---
title: Giving up quickly, on purpose
version: 1
---

A schema change that cannot get its lock should **fail fast rather than wait**, because waiting is
what blocks everybody else. PostgreSQL's `lock_timeout` sets how long a statement may wait for a
lock before giving up with an error. The same three terminals as the last section, with the
`ALTER TABLE` now limited to two seconds of waiting:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SET lock_timeout = '2s'" -c 'ALTER TABLE tickets ADD COLUMN scanned_at timestamptz'
SET
ERROR:  canceling statement due to lock timeout
```

The change gave up with **`canceling statement due to lock timeout`**, and nothing changed. The
sales running alongside:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1037 in 8.0 s = 129.5 per second
latency   p50 11.7 ms  p95 75.5 ms  p99 80.9 ms  max 1190.2 ms
status    201: 1037
```

**1037 sales in eight seconds, with a worst case of 1.19 s**: the stall lasted from the moment the
sales started until the `ALTER` gave up, about one second, instead of the whole length of the long
transaction. Lowering the timeout shortens the stall further.

## Retry, rather than wait

A change that fails on `lock_timeout` is tried again, a moment later, until it finds a gap. The
pattern every serious migration tool uses is:

1. set `lock_timeout` to something short, a few hundred milliseconds to a couple of seconds;
2. run the change;
3. on a lock timeout, wait a little and try again, up to a limit;
4. if it never gets through, stop and find the long transaction instead of waiting longer.

**`statement_timeout`** is its partner: it limits how long a statement may run in total, waiting
included. Set on the migration's session, it stops a change that turned out to rewrite the table
from holding its lock for minutes.

## Finding what is in the way

When a change keeps timing out, something holds a lock for a long time, and `pg_stat_activity`
names it: the `xact_start` column says when each connection's transaction began, and a transaction
that began an hour ago is the suspect. The most common one is **idle in transaction**: a program
that opened a transaction, did a query, and then waited for something else before committing.
PostgreSQL's `idle_in_transaction_session_timeout` ends such sessions after a set time, and setting
it for application connections removes the most common long lock holder from a busy database.
