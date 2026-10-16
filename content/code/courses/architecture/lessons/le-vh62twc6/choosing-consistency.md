---
title: Choosing consistency: synchronous replication
version: 1
---

With **synchronous replication**, the primary does not tell a client a write is committed until the
standby has confirmed that it has the change on disk. Losing the primary then loses nothing a client
was told about, which is why it is the setting for data that must not be lost. Turn it on; `*` means
"any one standby":

```
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM SET synchronous_standby_names = '*'" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~/lab/cap$ $P -c "SELECT client_addr, state, sync_state FROM pg_stat_replication"
 client_addr |   state   | sync_state 
-------------+-----------+------------
 172.18.0.3  | streaming | sync
(1 row)
```

`sync_state` is now `sync`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two sequences of a write from the client to the primary to the standby. Synchronous: the primary writes, sends the change to the standby, waits for the standby&#x27;s confirmation, and only then tells the client it is committed. Asynchronous: the primary writes and tells the client at once; the change reaches the standby afterwards.\"><defs><marker id=\"l8-sync-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8-sync-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">synchronous</text><rect x=\"20\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><path d=\"M65 74 L65 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"135\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><path d=\"M180 74 L180 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"250\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"295\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">standby</text><path d=\"M295 74 L295 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M68 96 L177 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"122.5\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE</text><path d=\"M183 126 L292 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"237.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">WAL</text><path d=\"M292 166 L183 166\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"237.5\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">flushed</text><path d=\"M177 206 L68 206\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-sync-ah-phosphor)\"></path><text x=\"122.5\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">COMMIT</text><text x=\"530\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">asynchronous</text><rect x=\"370\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"415\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">client</text><path d=\"M415 74 L415 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"485\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">primary</text><path d=\"M530 74 L530 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"600\" y=\"46\" width=\"90\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">standby</text><path d=\"M645 74 L645 266\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M418 96 L527 96\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-amber)\"></path><text x=\"472.5\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UPDATE</text><path d=\"M527 126 L418 126\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l8-sync-ah-amber)\"></path><text x=\"472.5\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">COMMIT</text><path d=\"M533 176 L642 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-sync-ah-amber)\"></path><text x=\"587.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">WAL, later</text></svg>", "caption": "Synchronous replication answers the client after the copy confirms; asynchronous answers before. The difference is a round trip on every commit, and what a partition does to each."}
```

## The partition

`docker network disconnect` removes the standby from the lab's network, which is a partition with
nothing else wrong: both servers are up, and neither can reach the other. Then try to sell one bag of
coffee, with `timeout 5` so that the shell gives up after five seconds:

```
ana@vm:~/lab/cap$ docker network disconnect cap_default cap-standby-1
ana@vm:~/lab/cap$ timeout 5 $P -c "UPDATE stock SET units = 11 WHERE sku = 'coffee'"; echo "exit code $?"

exit code 124
ana@vm:~/lab/cap$ $P -c "SELECT pid, wait_event, query FROM pg_stat_activity WHERE wait_event = 'SyncRep'"
 pid | wait_event |                      query                       
-----+------------+--------------------------------------------------
 106 | SyncRep    | UPDATE stock SET units = 11 WHERE sku = 'coffee'
(1 row)

ana@vm:~/lab/cap$ $P -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    12
(1 row)

ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    12
(1 row)
```

**The write did not come back.** After five seconds `timeout` killed the client, exit code 124, and the
primary is still sitting on the update: `pg_stat_activity` shows it waiting on `SyncRep`, for a standby
that cannot answer. Both servers still show 12 bags, because the waiting transaction is not visible to
anybody else until the wait ends.

This is the **C** choice of CAP, made by a configuration setting: rather than accept a write it cannot
copy, the primary stops accepting writes, **and for that data the system is unavailable for as long as
the partition lasts.** Reads still work on both sides, and they agree.

## When the network comes back

Reconnect the standby:

```
ana@vm:~/lab/cap$ docker network connect cap_default cap-standby-1
ana@vm:~/lab/cap$ $P -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    11
(1 row)

ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    11
(1 row)
```

The standby caught up, confirmed the change, and the primary finished the transaction that had been
waiting: both now say 11. **The client that sent it was never told**: it had given up and gone away.
From its point of view the sale failed, and in the database it succeeded. That is lesson 2's uncertain
outcome again, and the answer is again an idempotency key, so that the client's retry can be recognised
as the same sale.

Production setups usually soften the stop by naming two or more standbys and requiring an answer from
any one, `ANY 1 (s1, s2)`, so that one lost standby does not stop writes; losing all of them still does.
