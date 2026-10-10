---
title: Why clusters come in threes
version: 1
---

Lesson 6 said a production Kafka runs three nodes at least, and etcd, ZooKeeper and Consul's servers
are deployed in threes and fives, never in twos or fours. The reason is the failover problem from two
sections ago, stated precisely.

When the leader stops answering, the others have to decide whether to elect a new one. They cannot tell
a leader that has crashed from a leader that is running perfectly on the other side of a broken cable,
which lesson 8 showed is the definition of a partition. If they elect a new leader and the old one is
alive, there are two, and both accept writes. **The way out is to require a majority**: a group may
elect a leader, and a leader may accept writes, only while it can reach more than half of the nodes.
Two groups cannot both have more than half, so there can never be two leaders at once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three nodes split by a network partition into a group of two and a group of one. The group of two is a majority, two of three, and keeps a leader and keeps accepting writes. The single node is a minority and refuses writes. With only two nodes, a split leaves one on each side, and neither can tell whether the other has failed or is cut off.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"300\" height=\"150\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><circle cx=\"110\" cy=\"110\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"110\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">node 1</text><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">leader</text><circle cx=\"250\" cy=\"110\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"250\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">node 2</text><path d=\"M146 110 L214 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">2 of 3: a majority, keeps writing</text><text x=\"400\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">partition</text><path d=\"M400 84 L400 180\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><rect x=\"470\" y=\"40\" width=\"220\" height=\"150\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><circle cx=\"580\" cy=\"110\" r=\"34\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"580\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">node 3</text><text x=\"580\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1 of 3: refuses writes</text></svg>", "caption": "A majority of three is two, so one node can fail or be cut off and the rest carry on. Two nodes have no majority to spare: one alone is never more than half."}
```

Now count. With **two nodes**, a majority is two: the moment either one is unreachable, neither side has
a majority, and nothing can be written. Two nodes are less available than one, and in exchange give
you a copy of the data. With **three**, a majority is two, so one node can fail and the other two carry
on. With **four**, a majority is three, so still only one can fail: the fourth node added cost and no
tolerance. With **five**, a majority is three, and two can fail.

| nodes | majority | failures tolerated |
| --- | --- | --- |
| 1 | 1 | 0 |
| 2 | 2 | 0 |
| 3 | 2 | 1 |
| 4 | 3 | 1 |
| 5 | 3 | 2 |
| 7 | 4 | 3 |

The rule is **2f + 1 nodes to survive f failures**, and it is why the numbers are odd. Three is the
smallest cluster that survives losing a node; five is common where a node may be down for maintenance
when another one fails. Beyond that, each write waits for more machines to answer, and clusters rarely go
above seven voters.

This is the rule that **Raft** and **Paxos** are built on, the consensus protocols underneath etcd,
Consul, ZooKeeper (whose protocol, Zab, is a close relative), and Kafka's own controllers since KRaft.
A single-leader database such as PostgreSQL does not include one: its failover is decided by a tool
beside it, such as Patroni, which in turn stores its decision in one of those consensus stores. Lesson
19 uses one for a different purpose.
