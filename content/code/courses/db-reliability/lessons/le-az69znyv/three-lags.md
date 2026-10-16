---
title: Behind by how much, and measured how
version: 1
---

Lesson 11 left `pg_stat_replication` with four positions for each standby: where the log was **sent**,
**written**, **flushed** and **replayed**. Replication lag is the distance from the primary's own
current position to each of them, and it can be measured two ways: **in bytes**, as a distance in the
log, and **in time**, as how long a change took to get there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A horizontal line is the write-ahead log, older on the left and newer on the right. Five marks on it, from left to right: replay_lsn, flush_lsn, write_lsn, sent_lsn and the primary's current position, pg_current_wal_lsn(). A bracket from replay_lsn to the current position is labelled bytes behind; replay_lag is the time it took a change to cross that distance.\"><defs><marker id=\"l13p-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M30 90 L700 90\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l13p-wi)\"></path><text x=\"40\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">older</text><text x=\"690\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">newer</text><path d=\"M150 80 L150 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"150\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">replay_lsn</text><text x=\"150\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the standby's data</text><path d=\"M290 80 L290 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"290\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">flush_lsn</text><text x=\"290\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">on the standby's disk</text><path d=\"M400 80 L400 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"400\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">write_lsn</text><path d=\"M500 80 L500 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"500\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sent_lsn</text><text x=\"500\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sent by the primary</text><path d=\"M630 80 L630 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"630\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">pg_current_wal_lsn()</text><text x=\"630\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the primary, now</text><path d=\"M150 160 L150 168 L630 168 L630 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"390\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">bytes behind: pg_wal_lsn_diff(current, replay_lsn)</text></svg>", "caption": "The four positions pg_stat_replication reports for a standby, against the primary's own. Bytes behind is the distance on this line; the _lag columns are how long a change took to travel it."}
```

`pg_wal_lsn_diff` subtracts two positions and gives bytes, and `pg_size_pretty` makes them legible. The
three `_lag` columns are the time measurements: for recent commits, how long after the primary flushed
them the standby reported having written, flushed and replayed them. Measure both while `pgbench`
keeps the primary busy for twenty seconds in the background:

```
ana@vm:~$ pgbench -c 4 -T 20 -n bench > /dev/null 2>&1 &
shop=# \x
Expanded display is on.

shop=# SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;
-[ RECORD 1 ]----+----------------
application_name | standby1
behind           | 400 bytes
write_lag        | 00:00:00.000071
flush_lag        | 00:00:00.000359
replay_lag       | 00:00:00.000359
```

**400 bytes and a third of a millisecond**: on one machine, under load, the standby is a fraction of a
transaction behind. The two kinds of number answer different questions, and an alert needs both:

| | answers | grows when |
|---|---|---|
| bytes behind (`replay_lsn`) | how much log would be lost, or has to be replayed before a promotion | the primary writes faster than the standby keeps up |
| `replay_lag` | how old a read on the standby can be | the standby is slow, paused, or blocked |
| `write_lag`, `flush_lag` | how slow the network and the standby's disk are | the link or the disk is slow |

A large `replay_lag` with small `write_lag` and `flush_lag` means the log is arriving and sitting on
the standby's disk unreplayed: the network is fine, and the problem is on the standby. That reading of
the three columns is the first step of most lag investigations.
