---
title: The slot that nobody reads
version: 1
---

A slot promises its reader that no change will be lost. **PostgreSQL keeps that promise by keeping
every byte of WAL the slot has not consumed** — on the source's disk, for as long as it takes.

At the start of this lesson the lab also created a second slot, `forgotten`, and nothing ever read
it. Fourteen days of trade later:

```
ana@vm:~/etl$ psql -q -c CHECKPOINT && python apply_cdc.py
0 changes read up to -: {'INSERT': 0, 'UPDATE': 0, 'DELETE': 0, 'other tables': 0}
ana@vm:~/etl$ psql -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal FROM pg_replication_slots"
 slot_name | active | retained_wal 
-----------+--------+--------------
 wh_cdc    | f      | 176 bytes
 forgotten | f      | 6085 kB
(2 rows)

ana@vm:~/etl$ psql -c "SHOW max_slot_wal_keep_size"
 max_slot_wal_keep_size 
------------------------
 -1
(1 row)

ana@vm:~/etl$ psql -c "SELECT pg_drop_replication_slot('forgotten')"
 pg_drop_replication_slot 
--------------------------
 
(1 row)
```

The slot that is read every night holds back 176 bytes. The forgotten one holds back every byte of
WAL written since it was created, 6085 kB for fourteen days of a small shop: a little over 400 kB
a day here, and gigabytes a day on a busy production database.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l05-slots\" aria-label=\"The write-ahead log drawn as a strip, oldest on the left. The slot wh_cdc sits near the right-hand end, so almost nothing behind it is kept. The slot forgotten sits at the left-hand end, where it was created, and every byte between it and the end of the log is kept on the source's disk: 6085 kB after fourteen days.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"60.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the write-ahead log, on the source's disk</text><rect x=\"61.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"86.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"111.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"136.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"161.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"186.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"211.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"236.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"261.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"286.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"311.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"336.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"361.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"411.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"436.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"461.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"486.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"511.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"536.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"561.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"586.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"611.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"636.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">older</text><text x=\"660.0\" y=\"148.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">now</text><path d=\"M110.0 82.0 L110.0 134.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"110.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">forgotten</text><path d=\"M666.0 82.0 L666.0 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"666.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">wh_cdc</text><path d=\"M110.0 170 L666.0 170\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"388.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">kept for forgotten: 6085 kB</text><text x=\"666.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">176 bytes (wh_cdc)</text></svg>", "caption": "PostgreSQL keeps every byte a slot has not consumed. A slot nobody reads keeps all of them, until the disk is full."}
```

**The WAL lives on the same disk as the database.** When that disk fills, the database stops
taking writes, and the tills stop with it.

This is the commonest way change data capture takes down the system it reads from, and the shape is
always the same. A pipeline is decommissioned, or crashes and is not restarted, or its consumer is
paused for a migration, and its slot stays behind, holding WAL, with nothing on any screen saying
so.

## Three defences

- **A limit.** `max_slot_wal_keep_size` caps how much WAL a slot may hold back; past it, PostgreSQL
  invalidates the slot rather than fill the disk. The lab's value, `-1`, is the default: no limit.
  With a limit, the source survives and the pipeline loses its place, and has to start again from a
  new copy — which is the right way round.
- **Watch the number.** `pg_replication_slots` is a view anybody can query, and the retained WAL per
  slot is one expression. An alert on it is lesson 10's business; the number is here.
- **Drop what you no longer use.** A slot is removed by name, and the WAL it held is released at
  the next checkpoint. The lab drops `forgotten` as the last line above, and `lab.sh reset` drops
  every slot in the cluster.
