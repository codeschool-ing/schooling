---
title: What it costs
version: 1
---

**`log_statement = 'all'` writes every statement the server receives**, and it is the setting
people reach for when they want to know what an application is doing. It looks like the safe,
thorough choice. The cost is easy to measure, so measure it before turning it on anywhere real.

## A fixed run

pgbench's own test is a good yardstick because it is fixed: every transaction is the same seven
statements. First the connection lines and the slow-statement threshold go, so that what is left is
logging that writes only when something goes wrong:

```
shop=# ALTER SYSTEM RESET log_connections;
ALTER SYSTEM

shop=# ALTER SYSTEM RESET log_disconnections;
ALTER SYSTEM

shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

Then a database for it, at scale 10 (a million rows in its main table):

```
ana@db:~$ createdb bench
ana@db:~$ pgbench -i -q -s 10 bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
1000000 of 1000000 tuples (100%) done (elapsed 0.72 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.13 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.74 s, vacuum 0.13 s, primary keys 0.25 s).
```

The `NOTICE` lines are pgbench making sure no old tables are in the way. Now a script that runs
exactly 10,000 transactions — four connections, 2,500 each — and reports how many bytes the log
grew by. Save it as `logcost.sh`:

```bash
#!/usr/bin/env bash
# logcost.sh: how many bytes one fixed pgbench run adds to the server log
log=/var/log/postgresql/postgresql-16-main.log
before=$(sudo stat -c %s "$log")
pgbench -n -c 4 -t 2500 bench | grep -E 'processed|tps'
after=$(sudo stat -c %s "$log")
echo "the log grew by $((after - before)) bytes"
```

Run it once with the logging as it stands:

```
ana@db:~$ bash logcost.sh
number of transactions actually processed: 10000/10000
tps = 1555.658264 (without initial connection time)
the log grew by 0 bytes
```

Nothing. None of the 70,000 statements was slow, waited for a lock or spilled to disk.

## Every statement

```
shop=# ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@db:~$ bash logcost.sh
number of transactions actually processed: 10000/10000
tps = 1283.249475 (without initial connection time)
the log grew by 8758557 bytes
ana@db:~$ sudo tail -n 7 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:45:02.948 -03 [336] ana@bench pgbench LOG:  statement: BEGIN;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: UPDATE pgbench_accounts SET abalance = abalance + 4997 WHERE aid = 315396;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: SELECT abalance FROM pgbench_accounts WHERE aid = 315396;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: UPDATE pgbench_tellers SET tbalance = tbalance + 4997 WHERE tid = 76;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: UPDATE pgbench_branches SET bbalance = bbalance + 4997 WHERE bid = 9;
2026-10-10 16:45:02.949 -03 [336] ana@bench pgbench LOG:  statement: INSERT INTO pgbench_history (tid, bid, aid, delta, mtime) VALUES (76, 9, 315396, 4997, CURRENT_TIMESTAMP);
2026-10-10 16:45:02.952 -03 [336] ana@bench pgbench LOG:  statement: END;
```

**8758557 bytes for 10,000 transactions**: about 876 bytes a transaction, 125 a statement, every one
of them a line like the seven above, which are one whole transaction from one process. The
arithmetic is what matters. A modest application doing 100 transactions a second, around the clock,
would write 876 × 100 × 86,400 bytes, about 7.6 GB of log a day, from this setting alone.

Throughput is the cost people expect, and on the recording machine it could not be read off these
runs: pgbench reported 1555.7 transactions a second with nothing logged, 1283.2 with every statement,
and 1875.2 in the next run, which also logged every statement. The machine was shared with other
work, and the noise was larger than the effect. Writing a line to a file the kernel buffers is
cheap per line. On a server already short of disk bandwidth, or one whose log sits on the same disk
as the data, it stops being cheap, and the place it shows is everybody's latency.

## Every statement, with its duration

`log_min_duration_statement = 0` is the other way to log everything: a threshold of zero
milliseconds catches every statement, and each line carries how long it took.

```
shop=# ALTER SYSTEM RESET log_statement;
ALTER SYSTEM

shop=# ALTER SYSTEM SET log_min_duration_statement = 0;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

```
ana@db:~$ bash logcost.sh
number of transactions actually processed: 10000/10000
tps = 1875.154817 (without initial connection time)
the log grew by 10159212 bytes
ana@db:~$ sudo tail -n 1 /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:45:10.194 -03 [364] ana@bench pgbench LOG:  duration: 2.666 ms  statement: END;
```

10159212 bytes, 1.4 MB more than `log_statement = 'all'` for the same run, because every line
carries `duration: … ms` as well. In return each line says how long its statement took, which is
the version of *log everything* worth having during a short investigation: the slow statement is
at least labelled.

```
shop=# ALTER SYSTEM RESET log_min_duration_statement;
ALTER SYSTEM

shop=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)
```

## What the bytes buy

The disk is the cost you can count, and it is not the only one. A log that size has to be rotated,
compressed, shipped and searched, and **a line that matters is now one in tens of thousands**. The
slow statement, the lock wait and the error are all still in there, buried under every `BEGIN` and
`END` the application ever sent. And every literal in every statement is in the file in plain text:
the customer's email, the address, the password of the previous lesson's `crypt` call.

So `log_statement = 'all'` is a tool for a short window — a few minutes on a test server, or one
role with `ALTER ROLE … SET log_statement = 'all'` while you watch one application — and never a
default. **`log_statement = 'ddl'` is the useful permanent value**: it records every `CREATE`,
`ALTER` and `DROP`, which on most servers is a handful of lines a week and exactly the ones somebody
asks about after a table disappears.
