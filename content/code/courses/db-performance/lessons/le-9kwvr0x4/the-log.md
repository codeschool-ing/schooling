---
title: The log, for the one slow run
version: 1
---

`pg_stat_statements` adds runs together, and adding is what makes it good at finding where the
time goes. It is also what makes it blind to a single event. A statement whose mean is 9
milliseconds may have had one run that took two seconds at 03:12 last night, and the tally keeps
that only as one more contribution to `max_exec_time`, with no time, no parameters and no session
attached.

For that, the server's **log** is the other half. The setting `log_min_duration_statement` makes
the server write a line for every statement that takes longer than a threshold, with the moment it
finished, the process that ran it, the role and the database, and the statement **with its real
values**. It needs no restart — a reload is enough, because the setting can change while the server
runs:

```
market=# ALTER SYSTEM SET log_min_duration_statement = '50ms';
ALTER SYSTEM
Time: 2.682 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.699 ms
ana@vm:~/workload$ pgbench -n -c 4 -T 10 -f seller-dashboard.sql -f pending-count.sql market > /dev/null
```

Then a few seconds of two of the workload's scripts, and the end of the log file:

```
ana@vm:~$ sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log
	WHERE seller_id = 21 AND placed_at >= '2025-12-01'
	GROUP BY 1 ORDER BY 1;
2026-10-10 04:25:37.386 -03 [11018] ana@market LOG:  duration: 100.997 ms  statement: SELECT count(*) FROM orders WHERE status = 'pending';
2026-10-10 04:25:37.403 -03 [11017] ana@market LOG:  duration: 124.966 ms  statement: SELECT count(*) FROM orders WHERE status = 'pending';
```

The file is cut where `tail` cut it. The first two lines are the end of a longer entry: one run of
the seller dashboard that crossed 50 milliseconds, written as the application sent it, over several
lines, **with the seller it was for** — `seller_id = 21` — where `pg_stat_statements` would only
ever say `$2`. The last two are the operations screen's count, at 101 and 125 milliseconds, from two
different processes, the numbers in square brackets, seventeen milliseconds apart. That is the shape
the tally cannot show: **two people refreshed the same screen at the same moment, and each paid
the full price**.

## Choosing the threshold

The threshold is a trade between what you catch and what it costs. Every line is a write to a file
on the same disk as the database, and a threshold of zero logs every statement, which on a server
doing a thousand a second is a thousand lines a second and a measurable slowdown of its own. Two
settings are common in practice:

- **a few hundred milliseconds to a second** on a busy production server, to catch the outliers and
  nothing else;
- **zero, for a short window**, when you need to see everything an application does — for a
  minute, then back.

`db-administration` lesson 19 is about logging as a whole, what to record and at what cost. For
this course the log is a tool you switch on, read and switch off again:

```sql
ALTER SYSTEM RESET log_min_duration_statement;
SELECT pg_reload_conf();
```

## Which one to reach for

They answer different questions, and the mistake is to use one for the other's:

| question | tool |
|---|---|
| where does the server's time go, over a day? | `pg_stat_statements` |
| what happened at 03:12 last night? | the log |
| which values made this statement slow? | the log |
| did my fix make this statement cheaper? | `pg_stat_statements`, reset before and read after |

The log answers with **evidence about one run**: a time, a process, the exact values. The tally
answers with **arithmetic over all of them**. A third tool sits between them: the `auto_explain` extension
writes a slow statement's **plan** into the same log, so that the evidence includes what the server
decided to do. A plan is what lesson 3 teaches you to read, and that is the moment it becomes
useful.
