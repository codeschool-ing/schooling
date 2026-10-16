---
title: The log line for the waits nobody watched
version: 1
---

Everything so far needed somebody in window D while the waiting was happening. Most lock waits are
over before anybody looks: a two-second stall at 03:00, a page that was slow for a minute after a
deploy. The usual belief is that a wait that did not end in an error leaves no trace. By default
that is true. **One setting makes the server write a line for every lock wait that lasts longer
than a second**, with the same facts window D had to go and find.

## Switching it on

`log_lock_waits` is off by default. Switch it on with `ALTER SYSTEM` and reload, as lesson 2 did
for the slow-query log; no restart is needed:

```
market=# ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM
Time: 2.562 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.758 ms

market=# SHOW deadlock_timeout;
 deadlock_timeout 
------------------
 1s
(1 row)

Time: 1.184 ms
```

The threshold is not a setting of its own. It is **`deadlock_timeout`**, the same one second after
which a waiting session checks for a deadlock, as lesson 12 section 06 showed. At that moment it
looks for a cycle and finds none, and with `log_lock_waits` on, it writes down that it is still
waiting.
One check, two uses, and no cost at all for waits shorter than a second.

## A wait, recorded

Two windows. Window A changes order 3 and holds the transaction open for a few seconds before
committing; window B tries to change the same order meanwhile:

```
market=# BEGIN;
BEGIN
Time: 0.475 ms

market=*# UPDATE orders SET status = 'shipped' WHERE id = 3;
UPDATE 1
Time: 1.796 ms

market=*# COMMIT;
COMMIT
Time: 2.432 ms
```

```
market=# UPDATE orders SET status = 'cancelled' WHERE id = 3;
UPDATE 1
Time: 7288.342 ms (00:07.288)
```

Window B waited **7288 ms**. Now read the log:

```
ana@vm:~$ sudo tail -n 8 /var/log/postgresql/postgresql-16-main.log
2026-10-15 21:52:04.088 -03 [5743] LOG:  parameter "log_lock_waits" changed to "on"
2026-10-15 21:52:07.220 -03 [5813] ana@market LOG:  process 5813 still waiting for ShareLock on transaction 1609209 after 1000.266 ms
2026-10-15 21:52:07.220 -03 [5813] ana@market DETAIL:  Process holding the lock: 5811. Wait queue: 5813.
2026-10-15 21:52:07.220 -03 [5813] ana@market CONTEXT:  while updating tuple (0,3) in relation "orders"
2026-10-15 21:52:07.220 -03 [5813] ana@market STATEMENT:  UPDATE orders SET status = 'cancelled' WHERE id = 3;
2026-10-15 21:52:13.504 -03 [5813] ana@market LOG:  process 5813 acquired ShareLock on transaction 1609209 after 7284.947 ms
2026-10-15 21:52:13.504 -03 [5813] ana@market CONTEXT:  while updating tuple (0,3) in relation "orders"
2026-10-15 21:52:13.504 -03 [5813] ana@market STATEMENT:  UPDATE orders SET status = 'cancelled' WHERE id = 3;
```

Two entries, one when the wait passed a second and one when it ended, and between them the whole
incident:

- **`still waiting for ShareLock on transaction 1609209 after 1000.266 ms`** — process 5813 has
  been waiting a second for another transaction to end, which, as section 02 of this lesson showed,
  is what waiting for a row looks like.
- **`Process holding the lock: 5811. Wait queue: 5813.`** — who it was waiting for, and who else was
  in line. This is `pg_blocking_pids` written down at the moment it mattered.
- **`while updating tuple (0,3) in relation "orders"`** — the row, page 0, tuple 3: order 3.
- **`STATEMENT:`** — the waiting statement, in full.
- **`acquired ShareLock … after 7284.947 ms`** — when the wait ended, and how long it was. The
  difference from window B's own 7288 ms is the time the update itself took once it had the lock.

What the log does **not** say is what process 5811 was doing, because 5811 was not waiting and wrote
nothing. Add the process id to every log line, which Ubuntu's default `log_line_prefix` already
does (the `[5813]` after the time), and the holder's earlier statements are in the same file, under
its own number, if the slow-query log of lesson 2 or a statement log caught them.

## What it costs, and where it fits

A line per wait longer than `deadlock_timeout`, written by the waiting session itself. On a healthy
server that is close to nothing; on a server with a lock problem it is a few lines a second, which
is the point. **Leave it on.** Lowering `deadlock_timeout` to see shorter waits is tempting and
usually wrong: every waiting session then pays for a deadlock check sooner, and the default exists
because a second is a long wait for a transaction that is going to finish.

The three tools of this lesson cover three moments. **The log** tells you, the next morning, that
waits happened, how long they were and which row they were on. **`blocked.sql` and
`lock-tree.sql`** tell you, during an incident, who the root is right now. **`pg_locks`** tells
you, when the other two are not enough, exactly which lock on what. Lesson 23 turns the first two
into alerts.

On a server you run, leave it on. On this course's machine, switch it back off before lesson 14,
so that the configuration is the one every lesson starts from, and put `market` back:

```sql
ALTER SYSTEM RESET log_lock_waits;
SELECT pg_reload_conf();
```

Then close every window and run `~/reset-market.sh`.
