---
title: A consumer group shares the partitions
version: 1
---

**Copies of a program that use the same `group.id` share a topic's partitions between them: each
partition is read by exactly one member of the group.** That is how Kafka spreads the work of one
program over several processes or machines, and it is the queue-like behaviour lesson 2 promised:
inside a group, each message is handled once. Between groups nothing is shared. Every group reads
every message, at its own place, which is the log behaviour.

You need more shells for this one; open them as lesson 1 showed, with `multipass shell stream` in
more windows of your computer's terminal. In two of them, start two members of a new group,
`shelf`, one after the other: `python consumer.py a --group shelf` in one, and a few seconds later
`python consumer.py b --group shelf` in the next.

`a` started alone and read all ten sales from every partition, as `c1` did. When `b` joined, the
partitions were dealt again. In a third shell, ask who has what:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group shelf

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
shelf           sales           0          4               4               0               rdkafka-6ca0753c-f173-40e0-9a91-f0f99a179b6a /127.0.0.1      rdkafka
shelf           sales           1          4               4               0               rdkafka-6ca0753c-f173-40e0-9a91-f0f99a179b6a /127.0.0.1      rdkafka
shelf           sales           2          2               2               0               rdkafka-9547e082-fcb7-45cf-834b-6beee12b671b /127.0.0.1      rdkafka
```

Two members, told apart by `CONSUMER-ID`: one holds partitions 0 and 1, the other partition 2.
Three partitions between two members cannot be split evenly, and one member has two. The offsets
are those `a` reached reading alone, 4, 4 and 2, so whichever member now holds a partition carries
on from there; **the position belongs to the group, not to the member**.

Now start `python consumer.py c --group shelf` in another shell, and `d` the same way in one more,
and send ten more sales:

```
ubuntu@stream:~/work$ python producer.py
delivered per partition: {0: 4, 1: 4, 2: 2}
```

Then stop all four with Ctrl+C and look at what each one printed. `a` read the whole topic first,
alone, and then:

```
ubuntu@stream:~/work$ python consumer.py a --group shelf
a: assigned [0, 1, 2]
a: partition 2 offset 0 rec-000005
a: partition 2 offset 1 rec-000010
a: partition 1 offset 0 car-000002
a: partition 1 offset 1 nat-000003
a: partition 1 offset 2 car-000007
a: partition 1 offset 3 nat-000008
a: partition 0 offset 0 oli-000001
a: partition 0 offset 1 joa-000004
a: partition 0 offset 2 oli-000006
a: partition 0 offset 3 joa-000009
a: revoked [0, 1, 2]
a: assigned [2]
a: revoked [2]
a: assigned [2]
a: revoked [2]
a: assigned [2]
a: partition 2 offset 2 rec-000005
a: partition 2 offset 3 rec-000010
a: revoked [2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group shelf
b: assigned [0, 1]
b: revoked [0, 1]
b: assigned [1]
b: revoked [1]
b: assigned [1]
b: partition 1 offset 4 car-000002
b: partition 1 offset 5 nat-000003
b: partition 1 offset 6 car-000007
b: partition 1 offset 7 nat-000008
b: revoked [1]
```

```
ubuntu@stream:~/work$ python consumer.py c --group shelf
c: assigned [0]
c: revoked [0]
c: assigned [0]
c: partition 0 offset 4 oli-000001
c: partition 0 offset 5 joa-000004
c: partition 0 offset 6 oli-000006
c: partition 0 offset 7 joa-000009
c: revoked [0]
```

**Each of the ten new sales was read once, by one member**: `a` read partition 2's two, `b`
partition 1's four, `c` partition 0's four. `b` began with partitions 0 and 1, gave up 0 when `c`
arrived, and kept 1. And `d` read nothing; the next section is about why.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The topic sales with partitions 0, 1 and 2 in the middle. On the right, group shelf with four members: c reads partition 0, b partition 1, a partition 2, and d has no partition. On the left, group stock with one member, c1, which reads all three partitions. Each group keeps its own offsets.\" data-fig=\"l4-group\"><defs><marker id=\"l4-group-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">topic sales</text><rect x=\"290\" y=\"70\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partition 0</text><rect x=\"290\" y=\"120\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partition 1</text><rect x=\"290\" y=\"170\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partition 2</text><rect x=\"30\" y=\"95\" width=\"170\" height=\"80\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"115\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">group stock</text><rect x=\"80\" y=\"125\" width=\"70\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c1</text><path d=\"M 286 85 L 154 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l4-group-ah-8343)\"></path><path d=\"M 286 135 L 154 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l4-group-ah-8343)\"></path><path d=\"M 286 185 L 154 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l4-group-ah-8343)\"></path><rect x=\"520\" y=\"45\" width=\"170\" height=\"195\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">group shelf</text><rect x=\"570\" y=\"83\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c</text><line x1=\"434\" y1=\"85\" x2=\"566\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4-group-ah-8343)\"></line><rect x=\"570\" y=\"123\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">b</text><line x1=\"434\" y1=\"135\" x2=\"566\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4-group-ah-8343)\"></line><rect x=\"570\" y=\"163\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a</text><line x1=\"434\" y1=\"185\" x2=\"566\" y2=\"176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l4-group-ah-8343)\"></line><rect x=\"570\" y=\"201\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"605\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">d</text><text x=\"665\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">idle</text></svg>", "caption": "Inside a group each partition has one reader; between groups, every group reads everything."}
```

## Two groups, two readers

Group `stock` from the last section was not affected by any of this. It is a different group, so
it has its own offsets, still at 4, 4 and 2, and the ten new sales are waiting for it. **Adding a
group never takes anything from another group.** That is how the four systems of lesson 2 read the
same sales: the stock system as one group, the loyalty scheme as another, each with as many members
as its own load needs.
