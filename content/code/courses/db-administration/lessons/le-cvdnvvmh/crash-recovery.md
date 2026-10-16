---
title: Killing the server in the middle of a write
version: 1
---

The fear after a database crash is that the data is damaged and somebody now has to find a backup.
For a crash of the server process, that is almost never true. **You start it again, and it repairs
itself from the log**, because everything this lesson and the last have described exists for
this moment. Lesson 3 promised to do it on purpose, and this section does: a stream of commits, a
`kill -9` in the middle of them, and a check that every commit anybody was told about survived.

One thing to be honest about first. `kill -9` ends the server's processes and nothing else. The
operating system keeps running, and so does its cache of data that was handed to it but not yet
on the disk. A power cut loses that cache too, and surviving it is the job of the next section's
`fsync`. The recovery you are about to watch is the same in both cases; what differs is whether
the log it replays was really on the disk.

## A client that keeps a record

Make a table, then start a client that inserts numbers into it one at a time, each in its own
transaction, and writes down every number the server confirmed:

```
shop=# CREATE TABLE acks (id int PRIMARY KEY);
CREATE TABLE
ana@db:~$ seq 1 1000000 | sed 's/.*/INSERT INTO acks VALUES (&) RETURNING id;/' | psql -XAtq shop > acked.txt 2> acked.err &
ana@db:~$ pgbench -n -c 4 -T 120 bench > bench.out 2>&1 &
ana@db:~$ wc -l acked.txt
12910 acked.txt
```

`seq` counts, `sed` turns each number into an `INSERT`, and `psql` runs them one after another.
`RETURNING id` makes it print the number, and `psql` prints a statement's result only once the
statement has finished, which for a statement outside a transaction block includes its commit.
So **`acked.txt` is the client's own list of commits it was told about**. The `&` at the end of
each line runs it in the background; the second line adds `pgbench` for two minutes as the rest of
the write load. Ten seconds later the list had 12910 numbers.

Now kill the server's main process, the postmaster, whose process id is the first line of
`postmaster.pid` (lesson 4 printed that file):

```
ana@db:~$ sudo kill -9 $(sudo head -n 1 /var/lib/postgresql/16/main/postmaster.pid)
ana@db:~$ tail -n 1 acked.txt
13003
ana@db:~$ cat acked.err
FATAL:  terminating connection due to unexpected postmaster exit
no connection to the server
connection to server was lost
ana@db:~$ tail -n 2 bench.out
tps = 2183.802426 (without initial connection time)
pgbench: error: Run was aborted; the above results are incomplete.
ana@db:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 down   postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

The last commit the client heard about was **13003**. Its session was ended with
`unexpected postmaster exit`: the processes serving connections noticed their parent had gone and
stopped, because none of them may go on alone. `pgbench` was cut off too, and the cluster is down.
Nothing restarted it. The unit that runs it does not ask systemd for automatic restarts, so on this
server a crash stays down until somebody acts — which is when an administrator is paged.

## The recovery, line by line

Start it the ordinary way, and read what it wrote:

```
ana@db:~$ sudo systemctl start postgresql@16-main
ana@db:~$ sudo tail -n 11 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:29:00.013 -03 [332] LOG:  starting PostgreSQL 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0, 64-bit
2026-10-10 04:29:00.013 -03 [332] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2026-10-10 04:29:00.014 -03 [332] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 04:29:00.019 -03 [335] LOG:  database system was interrupted; last known up at 2026-10-10 04:28:27 -03
2026-10-10 04:29:00.294 -03 [335] LOG:  database system was not properly shut down; automatic recovery in progress
2026-10-10 04:29:00.298 -03 [335] LOG:  redo starts at 0/420F91E0
2026-10-10 04:29:01.032 -03 [335] LOG:  invalid record length at 0/535AA2E0: expected at least 24, got 0
2026-10-10 04:29:01.032 -03 [335] LOG:  redo done at 0/535AA2B8 system usage: CPU: user: 0.42 s, system: 0.30 s, elapsed: 0.73 s
2026-10-10 04:29:01.039 -03 [333] LOG:  checkpoint starting: end-of-recovery immediate wait
2026-10-10 04:29:01.581 -03 [333] LOG:  checkpoint complete: wrote 16289 buffers (99.4%); 0 WAL file(s) added, 0 removed, 17 recycled; write=0.110 s, sync=0.421 s, total=0.543 s; sync files=52, longest=0.179 s, average=0.009 s; distance=283332 kB, estimate=283332 kB; lsn=0/535AA2E0, redo lsn=0/535AA2E0
2026-10-10 04:29:01.593 -03 [332] LOG:  database system is ready to accept connections
```

After the three lines every start writes, the story is in order:

- `database system was interrupted; last known up at …` — `pg_control` still said `in production`,
  so the last stop was not a clean one. The time is that of the last checkpoint.
- `automatic recovery in progress` — nobody chooses this; it is what a start after a crash does.
- `redo starts at 0/420F91E0` — the redo point of the last checkpoint, read from `pg_control`,
  exactly as the figure in the first section drew it.
- `invalid record length at …: expected at least 24, got 0` — the end of the log. Recovery
  reads records until the next one is not valid, and here the next bytes were zeros, never
  written. It is reported as a `LOG` line, not an error, because every recovery ends this way.
- `redo done at … elapsed: 0.73 s` — every change since the redo point has been made again.
  `distance=283332 kB` on the next line is how much log that was.
- `end-of-recovery immediate wait` — a checkpoint, so that the repaired pages are on disk before
  anybody connects, and the next crash will not have to replay the same log again.

Then the only check that matters:

```
shop=# SELECT max(id), count(*) FROM acks;
  max  | count 
-------+-------
 13003 | 13003
(1 row)
```

**Every number the client was told had committed is in the table: 13003 of them, the last one
included, and no gap.** The row that matched the last confirmation had not reached the table's file
when the server died; it was rebuilt from the log. A count one higher than the client's list would
have been correct too: a commit can reach the disk in the instant before the server could send its
reply. A count lower would mean a confirmed commit was lost, and that is the one result a correctly
configured PostgreSQL never gives.

How long this takes depends on how much log there is to replay, which is the distance from the
last checkpoint. Here it was 283332 kB, replayed in under a second. A server with a large `max_wal_size` and a
long `checkpoint_timeout`, under heavy writes, can replay for minutes, and **that wait is the price
of fewer checkpoints**, paid only on the day something crashes.
