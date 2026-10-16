---
title: Losing an acknowledged write, on purpose
version: 1
---

Lesson 1 promised this section: Redis with replicas leans PA/EL, and here it gives up consistency in
front of you. **A write the primary acknowledged with `OK` disappears, and no command returns an
error.** It takes a partition rather than a crash, because a crashed primary accepts nothing more; a
primary cut off from its replicas and its Sentinels, but still reachable by one client, accepts
everything.

## The partition

`docker network disconnect` takes a container off the network without stopping it. `docker exec` still
reaches the process inside, the way a client on the same side of a broken link would:

```
ana@vm:~$ docker exec $primary redis-cli SET order:2001 paid
OK
ana@vm:~$ docker network disconnect nosql $primary
ana@vm:~$ docker exec $primary redis-cli SET order:2002 paid
OK
ana@vm:~$ docker exec $primary redis-cli GET order:2002
paid
```

Order 2001 was written before the cut and replicated. **Order 2002 was written after it, answered `OK`,
and is readable on the primary.** As far as the client can tell, it is stored. The primary's replicas
and every Sentinel are on the other side of the cut, and five seconds later they declare it down and
promote a replica that has never heard of order 2002.

## Healing

```
ana@vm:~$ old=$primary; primary=$(docker exec sentinel-1 redis-cli -p 26379 SENTINEL get-master-addr-by-name shop | head -1); echo "old $old, new $primary"
old redis-2, new redis-3
ana@vm:~$ docker network connect nosql $old
ana@vm:~$ docker exec $old redis-cli INFO replication | grep -E "^(role|master_host|master_link_status):"
role:slave
master_host:redis-3
master_link_status:up
ana@vm:~$ docker exec $old redis-cli GET order:2002

ana@vm:~$ docker exec $primary redis-cli GET order:2002

ana@vm:~$ docker exec $old redis-cli GET order:2001
paid
ana@vm:~$ docker logs $old 2>&1 | grep -E "Full resync|Flushing old data"
1:S 10 Oct 2026 20:12:59.124 * Full resync from master: 0b1275213a56b27ef078aba47f45f4e75c32e5eb:0
1:S 10 Oct 2026 20:12:59.126 * MASTER <-> REPLICA sync: Flushing old data
1:S 10 Oct 2026 20:14:12.334 * Full resync from master: 2872a33f314c48a2f8dca8d2e0169739767a3cc0:7490468
1:S 10 Oct 2026 20:14:12.450 * MASTER <-> REPLICA sync: Flushing old data
```

When the old primary rejoined the network, Sentinel made it a replica of the new primary, and a
replica takes its primary's dataset: the log says **full resync**, then **flushing old data**. The second pair of lines, at 20:14:12, is the
rejoin; the first is from when `redis-2` started as a replica at the beginning of the lesson. Order
2002 is not on the old primary any more, not on the new one, and not anywhere. Order 2001, written
before the cut, is everywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Two moments. During the partition: redis-2, the old primary, is cut off with order 2001 and order 2002, and answered OK to both; across the cut, redis-3 has been promoted and holds order 2001 only, with redis-1 as its replica. After the partition heals: redis-2 has rejoined as a replica of redis-3, took a full copy, and holds order 2001 only. Order 2002 exists nowhere.\"><defs><marker id=\"l15lost-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">during the partition</text><rect x=\"20\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-2</text><text x=\"90.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">old primary, cut off</text><text x=\"90.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001  2002</text><line x1=\"175\" y1=\"30\" x2=\"175\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 4\"></line><rect x=\"190\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-3</text><text x=\"260.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">promoted</text><text x=\"260.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001</text><rect x=\"190\" y=\"150\" width=\"140\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"260.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-1</text><text x=\"260.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">its replica</text><text x=\"90\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">SET 2002: OK</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">after it heals</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-3</text><text x=\"450.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primary</text><text x=\"450.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001</text><rect x=\"540\" y=\"40\" width=\"140\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-2</text><text x=\"610.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replica: full resync</text><text x=\"610.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2001</text><rect x=\"380\" y=\"150\" width=\"140\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">redis-1</text><text x=\"450.0\" y=\"182.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replica</text><line x1=\"520\" y1=\"75\" x2=\"538\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l15lost-ah-paper-dim)\"></line><text x=\"610\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">order 2002: gone</text><text x=\"350\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no command returned an error</text></svg>", "caption": "The write answered OK on the wrong side of the cut. When the cut heals, the old primary takes the new primary's data whole, and the write it alone had goes with its old data."}
```

Nothing is wrong with this Redis. It did what asynchronous replication does under a partition, and it
is the CAP choice of lesson 1 made by a real system: the isolated primary stayed available and gave
up consistency.

## `WAIT`: knowing, not preventing

`WAIT n timeout` blocks the client until `n` replicas have acknowledged its earlier writes, or the
timeout, in milliseconds, passes, and answers how many did. Run against the healthy primary, with two
safety settings that the next block explains:

```
ana@vm:~$ docker exec -it $primary redis-cli
127.0.0.1:6379> CONFIG SET min-replicas-to-write 1
OK
127.0.0.1:6379> CONFIG SET min-replicas-max-lag 10
OK
127.0.0.1:6379> SET order:2003 paid
OK
127.0.0.1:6379> WAIT 2 1000
(integer) 2
ana@vm:~$ docker network disconnect nosql $primary
```

`WAIT 2 1000` answered 2: both replicas have order 2003. Now the same primary, cut off again:

```
ana@vm:~$ docker exec -it $primary redis-cli
127.0.0.1:6379> SET order:2004 paid
OK
127.0.0.1:6379> WAIT 1 2000
(integer) 0
(2.00s)
127.0.0.1:6379> GET order:2004
"paid"
127.0.0.1:6379> SET order:2005 paid
(error) NOREPLICAS Not enough good replicas to write.
```

`SET order:2004` still answered `OK`. `WAIT 1 2000` waited its two seconds and answered **0**: no
replica has it. **`WAIT` did not undo the write**: `GET` shows it on the primary, where the next
failover will throw it away exactly like order 2002. What `WAIT` gives is knowledge: the application
learns that this write is at risk, and can tell the customer the order is not confirmed instead of
showing a receipt. Redis's documentation is explicit that `WAIT` does not make Redis strongly
consistent: a replica that acknowledged can still lose the write in a failover of its own.

## `min-replicas-to-write`: shrinking the window

The two settings in the first session are the other half. **`min-replicas-to-write 1` with
`min-replicas-max-lag 10` makes the primary refuse writes when fewer than one replica has answered it
in the last 10 seconds.** Twelve seconds after the cut, `SET order:2005` was refused with
`NOREPLICAS`. An isolated primary stops accepting writes it cannot replicate.

It does not close the window, it bounds it: for the first seconds after a cut, before the lag passes
the limit, the primary still accepts writes that will be lost, order 2004 among them. A smaller
`min-replicas-max-lag` shrinks the window and makes the primary refuse writes during ordinary network
hiccups as well. That is PACELC again, set by two numbers.
