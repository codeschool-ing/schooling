---
title: Lag, measured from both ends
version: 1
---

**Replication lag** is how far behind the primary a replica is. It sounds like one number and it is
three, measured at three steps of the copy, and it can be counted in bytes or in seconds, from the
primary or from the replica. Each reading answers a different question, and the commonest mistake
is to read one of them as if it answered another.

## The steps a change goes through

A commit on the primary writes its WAL and returns to the client. Then the WAL is **sent** to the
replica, which **writes** it to its own disk, **flushes** it so that it survives a crash, and
finally **replays** it, applying the change to its tables. Only after the replay can a query on the
replica see the change. `pg_stat_replication` has a position for each step and a time for each gap:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A commit travels left to right through five steps: committed on the primary, sent, written on the replica, flushed on the replica, and replayed. Three brackets measure from the commit: write_lag ends at written, flush_lag at flushed, and replay_lag at replayed, which is the only point where a query on the replica can see the change.\"><text x=\"14\" y=\"16\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the primary</text><text x=\"298\" y=\"16\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on the replica</text><rect x=\"14\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"76\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">committed</text><path d=\"M138 48 L156 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M156.0 48.0 L150.0 52.0 L150.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"156\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"218\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">sent</text><path d=\"M280 48 L298 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M298.0 48.0 L292.0 52.0 L292.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"298\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">written</text><path d=\"M422 48 L440 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M440.0 48.0 L434.0 52.0 L434.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"440\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"502\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">flushed</text><path d=\"M564 48 L582 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M582.0 48.0 L576.0 52.0 L576.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"582\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"644\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">replayed</text><text x=\"644\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">visible to queries</text><path d=\"M76 102 L76 110 L360 110 L360 102\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"354\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">write_lag</text><path d=\"M76 132 L76 140 L502 140 L502 132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"496\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">flush_lag</text><path d=\"M76 162 L76 170 L644 170 L644 162\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"638\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">replay_lag</text><text x=\"14\" y=\"204\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recovery_min_apply_delay holds a change between flushed and replayed.</text></svg>", "caption": "The three lags in pg_stat_replication are three distances from the same commit. Only the last one decides what a read on the replica sees."}
```

On a healthy replica on a fast network the three lags are milliseconds and almost equal. When they
come apart, the place they come apart says what is slow. A large `write_lag` is the network, and a
`flush_lag` well above it is the replica's disk. A `replay_lag` well above that is the replay
itself, which runs in a single process and can fall behind a primary that writes with many.

## Under a load of writes

Run lesson 2's purchase script alone for twenty seconds, four clients, then ask the primary:

```
ana@vm:~$ cd ~/workload && pgbench -n -c 4 -T 20 -P 10 -f place-order.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 10.0 s, 1487.1 tps, lat 2.675 ms stddev 1.722, 0 failed
progress: 20.0 s, 1665.4 tps, lat 2.393 ms stddev 1.102, 0 failed
transaction type: place-order.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
duration: 20 s
number of transactions actually processed: 31529
number of failed transactions: 0 (0.000%)
latency average = 2.527 ms
latency stddev = 1.438 ms
initial connection time = 18.863 ms
tps = 1576.710078 (without initial connection time)
market=# SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;
    write_lag    |    flush_lag    |   replay_lag    | bytes_behind 
-----------------+-----------------+-----------------+--------------
 00:00:00.000098 | 00:00:00.000689 | 00:00:00.000771 |            0
(1 row)

Time: 2.759 ms
```

**31529 orders in twenty seconds**, about 1577 a second, and when it was over the replica was
**0 bytes** behind, with every lag under a millisecond. Replay keeps up easily with this, and on one
machine the network is a socket. Between two machines in two buildings, the floor is the round trip
between them, and a burst of writes, a large `UPDATE` or an index build on the primary pushes the
lag up for as long as the replay takes to digest it.

## From the replica's side, and its trap

A replica cannot see `pg_stat_replication`. What it has is the commit time of the last transaction
it replayed, `pg_last_xact_replay_timestamp()`, and "now minus that" is the obvious way to say how
far behind it is. Ask it twice, ten seconds apart, with nothing being written:

```
market=# SELECT now() - pg_last_xact_replay_timestamp() AS behind;
     behind      
-----------------
 00:00:01.201852
(1 row)

Time: 1.040 ms
market=# SELECT now() - pg_last_xact_replay_timestamp() AS behind;
     behind      
-----------------
 00:00:11.929953
(1 row)

Time: 0.722 ms
```

**1.2 seconds, then 11.9**, and the replica is not behind at all: there is simply nothing new to
replay, so the last replayed commit gets older by the second. A monitor built on this number alone
pages somebody every night at three, when the shop is quiet. It is only a measure of lag **while the
primary is writing**; when it is not, compare positions instead, which the next reading does.

## Making lag visible on purpose

On one machine the lag is too small to see a stale read happen, so make it large and predictable.
**`recovery_min_apply_delay`** tells a replica to wait before replaying each commit until that long
has passed since the primary made it. It is a real tool, used to keep a replica a fixed time behind
so that a mistaken `DROP TABLE` can be caught before it reaches the copy; `db-reliability` lesson 20
uses it for that. Here it stands in for a busy network. Set ten seconds on the replica, write for five, and read both ends. Both `market=#` prompts
look alike: the `ALTER SYSTEM` and the last query run in `psql -p 5433 market`, on the replica, and
the query on `pg_stat_replication` runs on the primary:

```
market=# ALTER SYSTEM SET recovery_min_apply_delay = '10s';
ALTER SYSTEM
Time: 1.828 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.735 ms
ana@vm:~$ cd ~/workload && pgbench -n -c 4 -T 5 -f place-order.sql market | grep -E "^(number of transactions|tps)"
number of transactions actually processed: 9232
tps = 1843.688671 (without initial connection time)
market=# SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;
   write_lag    |    flush_lag    |   replay_lag    | bytes_behind 
----------------+-----------------+-----------------+--------------
 00:00:00.00035 | 00:00:00.005032 | 00:00:04.996743 |      8637096
(1 row)

Time: 2.127 ms
market=# SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), now() - pg_last_xact_replay_timestamp() AS behind;
 pg_last_wal_receive_lsn | pg_last_wal_replay_lsn |     behind      
-------------------------+------------------------+-----------------
 1A/70039A0              | 1A/67C6EF8             | 00:00:19.539915
(1 row)

Time: 0.764 ms
```

The primary's view: `write_lag` and `flush_lag` are still **under 6 milliseconds**, because the WAL
arrives and is saved at once; the delay is in the replay, and `replay_lag` reads **5.0 seconds**,
with **8637096 bytes** of WAL received and not yet applied. The replica's view says the same in
positions: it has received up to `1A/70039A0` and replayed only up to `1A/67C6EF8`. Its timestamp
reading, **19.5 seconds**, mixes the two problems of this section: the replica has not yet replayed
any commit from this run, so the last one it replayed is from the run before, which ended almost
twenty seconds earlier.

So, when you watch a replica:

- **From the primary**, `replay_lag` and the byte difference between `sent_lsn` and `replay_lsn`.
  Bytes never grow on an idle server.
- **From the replica**, `pg_last_wal_receive_lsn()` against `pg_last_wal_replay_lsn()` for what it
  has and has not applied, and the replay timestamp only while writes are flowing.
- **As a user would**, by writing and timing how long until a read on the replica sees it, which is
  what the next section does.

The ten-second delay stays on for section 04.
