---
title: PACELC: the choice made when nothing is broken
version: 1
---

Partitions are rare; most of the time the network works. CAP has nothing to say about that time, and
Daniel Abadi pointed out in 2012 that the more frequent trade-off lives there. He extended the theorem's
question into **PACELC**: if there is a **P**artition, choose **A**vailability or **C**onsistency;
**E**lse, choose **L**atency or **C**onsistency.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A decision tree. The first question is whether there is a partition. If yes, the system chooses between availability and consistency, which is CAP. If no, it still chooses, between latency and consistency, which is the else part of PACELC.\"><defs><marker id=\"l8-pacelc-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l8-pacelc-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"260\" y=\"30\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">is there a partition?</text><rect x=\"60\" y=\"130\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">yes: availability</text><text x=\"190\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">or consistency (CAP)</text><rect x=\"400\" y=\"130\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">no: latency</text><text x=\"530\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">or consistency (ELC)</text><path d=\"M320 76 L210 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-pacelc-ah-amber)\"></path><path d=\"M400 76 L510 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8-pacelc-ah-phosphor)\"></path><text x=\"190\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rare: when the network breaks</text><text x=\"530\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">always: on every request</text></svg>", "caption": "PACELC: if there is a Partition, choose Availability or Consistency; Else, choose Latency or Consistency. The second choice is made on every request."}
```

The "else" half is the synchronous replication of the previous sections, seen on a good day. Every
synchronous commit waits for a round trip to the standby, partition or not. Time 500 separate commits
in each mode:

```
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM SET synchronous_standby_names = '*'" -c "SELECT pg_reload_conf()" > /dev/null
ana@vm:~/lab/cap$ time (for i in $(seq 500); do echo "UPDATE stock SET units = units WHERE sku = 'coffee';"; done | $P -q)

real	0m0.755s
user	0m0.108s
sys	0m0.053s
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()" > /dev/null
ana@vm:~/lab/cap$ time (for i in $(seq 500); do echo "UPDATE stock SET units = units WHERE sku = 'coffee';"; done | $P -q)

real	0m0.566s
user	0m0.101s
sys	0m0.071s
```

The same 500 updates took 0.755 seconds with synchronous replication and 0.566 with asynchronous, on two
containers that sit on the same machine and answer each other in a fraction of a millisecond. **Put the standby in
another data centre, 30 ms away, and every commit pays 30 ms more**, on every write, every day, whether
or not anything ever breaks. That is the cost a system pays all the time to have the consistency it
wants during the rare partition.

## Where real systems sit

| system, as usually configured | during a partition | otherwise |
| --- | --- | --- |
| PostgreSQL with synchronous standbys | consistency: writes wait | consistency: every commit waits a round trip |
| PostgreSQL with asynchronous standbys | availability on the primary; standbys stale | latency: commits return at once |
| Cassandra, DynamoDB with eventually consistent reads | availability | latency |
| DynamoDB with strongly consistent reads | consistency for those reads | consistency, at a higher cost per read |
| etcd, ZooKeeper, Consul's store | consistency: the minority side refuses | consistency: every write waits for a majority |

The last row is the family that coordinates other systems, holding leader elections and configuration,
and lesson 19 uses one. They choose consistency in both halves on purpose, because two nodes both
believing they are the leader is the failure they exist to prevent.
