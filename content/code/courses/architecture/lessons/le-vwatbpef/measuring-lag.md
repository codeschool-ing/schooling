---
title: Measuring how far behind a copy is
version: 1
---

Lesson 8 said that what an asynchronous failover loses is the replication lag at the moment of failure,
and lesson 9 that a copy which is behind does not fail, so it has to be measured. This section measures
it. The lab is lesson 8's pair of servers again, in a directory of its own:

```sh
mkdir -p ~/lab/replication && cd ~/lab/replication
```

`replication.sh`:

```schooling-example
{"language": "sh", "file": "replication.sh", "parts": [{"code": "#!/bin/bash\nset -e\npsql -v ON_ERROR_STOP=1 -U \"$POSTGRES_USER\" -c \"CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicator'\"\necho \"host replication replicator all scram-sha-256\" >> \"$PGDATA/pg_hba.conf\"", "note": "Runs once, when the primary's data directory is first created: a role allowed to stream the write-ahead log, and a line in `pg_hba.conf` that lets it connect for replication from the lab's network."}]}
```

`compose.yaml`:

```schooling-example
{"language": "yaml", "file": "compose.yaml", "parts": [{"code": "services:\n  primary:\n    image: postgres:17\n    environment:\n      POSTGRES_PASSWORD: quitanda\n    volumes:\n      - ./replication.sh:/docker-entrypoint-initdb.d/replication.sh:ro\n      - primary:/var/lib/postgresql/data", "note": "The same two servers as lesson 8: PostgreSQL 17, a primary that takes the writes and runs `replication.sh` on its first start, and a standby that follows it."}, {"code": "  standby:\n    image: postgres:17\n    user: postgres\n    environment:\n      PGPASSWORD: replicator\n    command: >\n      bash -c \"until pg_basebackup -h primary -U replicator -D /var/lib/postgresql/data -R -X stream;\n               do sleep 1; done; chmod 700 /var/lib/postgresql/data; exec postgres\"\n    volumes:\n      - standby:/var/lib/postgresql/data\n    depends_on:\n      - primary\nvolumes:\n  primary:\n  standby:", "note": "The standby starts empty, copies the primary with `pg_basebackup`, and `-R` writes the settings that make it follow the primary from then on, streaming every change. It accepts reads and refuses writes."}]}
```

Start them, give them fifteen seconds, and set the two shell variables lesson 8 used, one for each
server:

```sh
docker compose up -d
P="docker compose exec -T primary psql -U postgres"
S="docker compose exec -T standby psql -U postgres"
```

The primary reports on every standby connected to it in `pg_stat_replication`:

```
ana@vm:~/lab/replication$ $P -x -c "SELECT state, sent_lsn, write_lsn, flush_lsn, replay_lsn, write_lag, flush_lag, replay_lag FROM pg_stat_replication"
-[ RECORD 1 ]---------
state      | streaming
sent_lsn   | 0/3000000
write_lsn  | 0/3000000
flush_lsn  | 0/3000000
replay_lsn | 0/3000000
write_lag  | 
flush_lag  | 
replay_lag | 
```

The four positions in the write-ahead log are the ones to read. `sent_lsn` is how far the primary has
sent the log to this standby, and `replay_lsn` how far the standby has applied it; an LSN, a log sequence
number, is a position in the log, in bytes. Between them sit `write_lsn` and `flush_lsn`, and the three
`_lag` columns turn the same steps into time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A strip of write-ahead log, growing to the right. Four markers along it: the primary&#x27;s current position at the far right, then sent, the point the standby has received over the network, then flushed, what the standby has written to its disk, and replayed, what the standby has applied and can show to a reader, furthest left. The distance from sent back to replayed is what the standby has and has not applied yet.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"90\" width=\"640\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">write-ahead log</text><path d=\"M660 124 L660 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"660\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">current</text><text x=\"660\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the primary is here</text><path d=\"M520 124 L520 150\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"520\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sent</text><text x=\"520\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">on the way to the standby</text><path d=\"M400 124 L400 150\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"400\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">flush</text><text x=\"400\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">on the standby's disk</text><path d=\"M220 124 L220 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"220\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">replay</text><text x=\"220\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">what readers of the standby see</text><rect x=\"220\" y=\"92\" width=\"300\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"370\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">received, not yet applied</text></svg>", "caption": "Each position in `pg_stat_replication` answers a different question: what the network carried, what is safe on the standby's disk, and what a reader of the standby can see."}
```

## Under load

`pgbench`, which ships with PostgreSQL, runs a standard banking-style workload. Create its tables, run
it for twenty seconds with eight clients in the background, and look at the lag while it runs:

```
ana@vm:~/lab/replication$ docker compose exec -T primary pgbench -i -q -U postgres postgres
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) of pgbench_accounts done (elapsed 0.10 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.29 s (drop tables 0.00 s, create tables 0.01 s, client-side generate 0.13 s, vacuum 0.11 s, primary keys 0.05 s).
ana@vm:~/lab/replication$ docker compose exec -d primary pgbench -T 20 -c 8 -U postgres postgres
ana@vm:~/lab/replication$ sleep 8; $P -c "SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication"
    write_lag    |    flush_lag    |   replay_lag    | bytes_behind 
-----------------+-----------------+-----------------+--------------
 00:00:00.000135 | 00:00:00.000135 | 00:00:00.000135 |          512
(1 row)
```

On one machine, with both servers in containers, the standby was **0.14 milliseconds** behind, and 512
bytes. Across a network, between data centres, the same columns show the round trip and whatever the
standby's disk adds. They are the numbers to graph, and to alert on.

## A standby that stops applying

Lag that matters comes from a standby that cannot keep up: a slow disk, a long query on the standby
holding back replay, a network that drops. PostgreSQL can imitate the last case on purpose, with
`pg_wal_replay_pause()`, which stops the standby applying the log while it keeps receiving it. Pause it,
write 200,000 rows on the primary, and look at both sides:

```
ana@vm:~/lab/replication$ $S -c "SELECT pg_wal_replay_pause()"
 pg_wal_replay_pause 
---------------------
 
(1 row)

ana@vm:~/lab/replication$ $P -c "INSERT INTO pgbench_history SELECT 1, 1, 1, 0, now() FROM generate_series(1, 200000)"
INSERT 0 200000
ana@vm:~/lab/replication$ $P -c "SELECT replay_lag, pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS behind FROM pg_stat_replication"
   replay_lag    | behind 
-----------------+--------
 00:00:00.284866 | 15 MB
(1 row)

ana@vm:~/lab/replication$ $S -c "SELECT count(*) FROM pgbench_history" -c "SELECT now() - pg_last_xact_replay_timestamp() AS last_replayed"
 count 
-------
 24699
(1 row)

  last_replayed  
-----------------
 00:00:04.689435
(1 row)
```

The primary shows the standby **15 MB behind**. The standby still counts the old number of rows, and
its last applied transaction is several seconds old. But `replay_lag` says 0.3 seconds, which is
misleading: it is the delay of the last change the standby *did* apply, and while nothing is applied it
does not grow. **The byte difference and the standby's own clock tell the truth here**; the time column
alone would have said everything was fine.

Resume, and the standby catches up in a moment:

```
ana@vm:~/lab/replication$ $S -c "SELECT pg_wal_replay_resume()"
 pg_wal_replay_resume 
----------------------
 
(1 row)

ana@vm:~/lab/replication$ sleep 3; $P -c "SELECT replay_lag, pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS behind FROM pg_stat_replication"
   replay_lag    | behind  
-----------------+---------
 00:00:00.955551 | 0 bytes
(1 row)

ana@vm:~/lab/replication$ $S -c "SELECT count(*) FROM pgbench_history"
 count  
--------
 224699
(1 row)
```

## What to watch

| question | where to read it |
| --- | --- |
| how much would a failover lose right now | `pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)` on the primary: what has not even left |
| how stale is a read from the standby | `now() - pg_last_xact_replay_timestamp()` on the standby, while the primary is writing |
| is the standby connected at all | a row in `pg_stat_replication` with `state = streaming`; no row is the alarm |

The last row is the one most often missed. A standby that has disconnected disappears from the view,
and a dashboard that graphs the lag of the rows it finds draws a flat, healthy line. And
`pg_last_xact_replay_timestamp` grows on its own when the primary is idle, since there is nothing new to
replay, so it means something only while writes are happening.
