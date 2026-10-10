---
title: When checkpoints happen
version: 1
---

A checkpoint costs a burst of writing, so it is tempting to think fewer is always better, or that
frequent small ones would be gentler. Neither holds. **Rare checkpoints make recovery long and
`pg_wal` large; frequent ones make the server write far more**, for a reason the section after this
one measures. Three settings place them:

```
shop=# SELECT name, setting, unit FROM pg_settings
shop-#  WHERE name IN ('checkpoint_timeout', 'max_wal_size', 'checkpoint_completion_target',
shop(#                 'checkpoint_warning', 'log_checkpoints');
             name             | setting | unit 
------------------------------+---------+------
 checkpoint_completion_target | 0.9     | 
 checkpoint_timeout           | 300     | s
 checkpoint_warning           | 30      | s
 log_checkpoints              | on      | 
 max_wal_size                 | 1024    | MB
(5 rows)
```

**A checkpoint starts at whichever comes first: `checkpoint_timeout` since the last one, or enough
log written.** The first kind is logged as `time` and the second as `wal`. Five minutes is the
default interval, and a server with nothing to write skips the timed checkpoint rather than doing
an empty one.

"Enough log" is not `max_wal_size` itself. The server wants the whole cycle — the log written while
a checkpoint runs plus the log written before the next one — to fit inside `max_wal_size`, so it
starts a checkpoint at a little under half of it. With the default 1 GB that is around 500 MB of
log between checkpoints.

`checkpoint_completion_target`, 0.9, spreads a routine checkpoint's writing over nine tenths of the
interval instead of doing it all at once, so the disk sees a steady trickle rather than a flood
every five minutes. `checkpoint_warning` is the alarm this section sets off.

## Checkpoints too often, on purpose

The usual way to get this wrong is a `max_wal_size` that was right for a quiet server and is far too
small for the write load it carries now. Build that. `pgbench`, which ships with PostgreSQL, makes a
database of its own and runs a standard write workload against it; `-s 20` makes it two million
account rows:

```
ana@db:~$ createdb bench
ana@db:~$ pgbench -i -s 20 -q bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
2000000 of 2000000 tuples (100%) done (elapsed 1.54 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 2.47 s (drop tables 0.00 s, create tables 0.00 s, client-side generate 1.56 s, vacuum 0.16 s, primary keys 0.74 s).
```

The `NOTICE` lines are `pgbench` clearing tables that were never there. Now shrink `max_wal_size`
with `ALTER SYSTEM`, as lesson 5 did, reload, and zero the two statistics views this section reads,
so that what they count afterwards is this run alone:

```
bench=# ALTER SYSTEM SET max_wal_size = '64MB';
ALTER SYSTEM

bench=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

bench=# CHECKPOINT;
CHECKPOINT

bench=# SELECT pg_stat_reset_shared('bgwriter'), pg_stat_reset_shared('wal');
 pg_stat_reset_shared | pg_stat_reset_shared 
----------------------+----------------------
                      | 
(1 row)
```

Then run a fixed amount of work: four clients (`-c 4`), ten thousand transactions each (`-t 10000`),
and `-n` to skip the vacuum `pgbench` would otherwise start with. Each of its transactions updates
three tables and inserts into a fourth:

```
ana@db:~$ pgbench -n -c 4 -t 10000 bench
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 20
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
number of transactions per client: 10000
number of transactions actually processed: 40000/40000
number of failed transactions: 0 (0.000%)
latency average = 1.540 ms
initial connection time = 10.716 ms
tps = 2597.530956 (without initial connection time)
ana@db:~$ sudo tail -n 5 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:28:24.044 -03 [102] LOG:  checkpoint starting: wal
2026-10-10 04:28:24.918 -03 [102] LOG:  checkpoint complete: wrote 3999 buffers (24.4%); 0 WAL file(s) added, 0 removed, 2 recycled; write=0.852 s, sync=0.009 s, total=0.874 s; sync files=18, longest=0.004 s, average=0.001 s; distance=32780 kB, estimate=106635 kB; lsn=0/40EAE6C8, redo lsn=0/3F004310
2026-10-10 04:28:24.953 -03 [102] LOG:  checkpoints are occurring too frequently (0 seconds apart)
2026-10-10 04:28:24.953 -03 [102] HINT:  Consider increasing the configuration parameter "max_wal_size".
2026-10-10 04:28:24.954 -03 [102] LOG:  checkpoint starting: wal
```

`tps` is transactions per second, and on its own it means little: this run measured 2597 on a
machine whose four processors and disk were shared with other work. The log says more. **Each
checkpoint started because of `wal`, and the next began the moment the last one finished.** The
`distance` is 32780 kB: with `max_wal_size` at 64 MB, a checkpoint fell due after every 32 MB or so
of log, a little under half, as above. And because two of them started less than
`checkpoint_warning` apart, the server said so, with a hint naming the setting to raise.

The statistics count the same story:

```
bench=# SELECT checkpoints_timed, checkpoints_req FROM pg_stat_bgwriter;
 checkpoints_timed | checkpoints_req 
-------------------+-----------------
                 0 |              14
(1 row)

bench=# SELECT wal_records, wal_fpi, pg_size_pretty(wal_bytes) AS wal FROM pg_stat_wal;
 wal_records | wal_fpi |  wal   
-------------+---------+--------
      269350 |   59334 | 461 MB
(1 row)
```

**Fourteen checkpoints in one short run, none of them timed.** `checkpoints_req` counts every
checkpoint the timer did not start: the ones forced by the log, and any `CHECKPOINT` command. On a
healthy server nearly all checkpoints are timed, and a `checkpoints_req` that keeps climbing, or a
log with that `HINT` in it, says `max_wal_size` is too small for the work. **Raising
`max_wal_size` is the fix, and it costs disk**: the directory may grow to about that size, and
recovery after a crash has more log to replay.

`pg_stat_wal` is the second half of the evidence, and the next section runs the same work again
at the default setting to compare it.
