---
title: Reprocessing beside the running version
version: 1
---

Replay moves an existing group back. **Reprocessing runs a new version of the program from the start,
under a new group, while the old one keeps serving.** The difference matters when the output is
something people are reading: moving the only consumer back to Monday means the stock page shows
Monday's numbers for as long as the catch-up takes. Running the new version beside it means the page
stays as it was, wrong in the old way, until the new one has caught up and been checked.

The pattern has a name borrowed from deployments, **blue-green**, and four steps:

1. **Start the new version under a new `group.id`.** A new group has no committed offsets, so with
   `auto.offset.reset=earliest` it reads the topic from its oldest message. Nothing about the old
   group changes.
2. **Give it its own output.** A new topic, `stock.v2`, or a new table. Two versions writing to the
   same place produce a mixture of both.
3. **Let it catch up, and compare.** Its lag reaches zero; its output agrees with the old one where
   the old one was right and differs where the bug was.
4. **Switch the readers, then retire the old version** and delete its group.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"One topic, sales, read by two consumer groups. The old version, group stock-count, writes to the output people read. The new version, group stock-v2, starts from the oldest message and writes to an output of its own. When the new one has caught up and its output has been checked, readers switch to it and the old group is deleted.\" data-fig=\"l16-bluegreen\"><defs><marker id=\"l16-bluegreen-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16-bluegreen-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"85\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sales</text><rect x=\"250\" y=\"30\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">old version</text><text x=\"345\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">group stock-count</text><rect x=\"250\" y=\"140\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">new version</text><text x=\"345\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">group stock-v2</text><path d=\"M 150 105 L 245 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-8343)\"></path><text x=\"195\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">at the end</text><path d=\"M 150 125 L 245 168\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-83)\"></path><text x=\"190\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">from the oldest message</text><rect x=\"500\" y=\"40\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock</text><rect x=\"500\" y=\"150\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stock.v2</text><path d=\"M 440 60 L 495 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-8343)\"></path><path d=\"M 440 170 L 495 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-83)\"></path><path d=\"M 545 85 L 545 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"560\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">compare</text><text x=\"655\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">readers today</text><path d=\"M 625 60 L 595 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-8343)\"></path><text x=\"655\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">after the switch</text><path d=\"M 625 170 L 595 170\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-bluegreen-ah-83)\"></path></svg>", "caption": "Blue-green reprocessing: the new version catches up beside the old one, and readers move only when it has."}
```

## The new group

The poison section left `stock-count` with a bad message dealt with. A second version of the counter,
under `stock-v2`, starts from the beginning of `sales`:

```
ubuntu@stream:~/work$ python sturdy_consumer.py --group stock-v2 --dead-letter sales.dlq
dead letter: sales/2/0 JSONDecodeError('Expecting value: line 1 column 1 (char 0)')
630 sales, 1042 books, 1 dead letters
```

The cluster now knows every group this lesson made, and the new one is at the end of the topic:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
console-consumer-64613
audit
stock-count
stock-v2
stock
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock-v2

Consumer group 'stock-v2' has no active members.

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID     HOST            CLIENT-ID
stock-v2        sales           0          139             139             0               -               -               -
stock-v2        sales           1          491             491             0               -               -               -
stock-v2        sales           2          1               1               0               -               -               -
```

Once the readers have moved to the new output, the old group is only a set of committed offsets
that nobody uses. Deleting it takes them away, so the group tools stop listing it and nobody resumes
from it by accident later. A group can be deleted only when no member is running:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --delete --group stock-count
Deletion of requested consumer groups ('stock-count') was successful.
```

## What reprocessing costs

**Everything the new version writes outside Kafka happens again.** The dead-letter topic is the
example in front of you: version 2 met the same bad sale and sent it to `sales.dlq` a second time,
so the topic now holds two copies of one problem. An email, a payment, a message to a supplier would
be sent twice in the same way. A new version that has side effects needs them switched off, pointed
at a copy, or made idempotent, which is lesson 8 again.

It also costs a full read of the topic, at whatever speed the new version manages. Reading a week
of sales takes the week's volume divided by the consumer's rate, and a consumer that handles ten sales
a second takes a long time over a busy week. Several instances in the new group share the partitions,
up to one per partition, which is lesson 4's rule and the reason the number of partitions is chosen
with reprocessing in mind.
