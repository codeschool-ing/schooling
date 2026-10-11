---
title: A node dies while the tills are selling
version: 1
---

**When a leader dies, the controllers notice that it has stopped sending heartbeats, pick a new
leader from the partition's ISR, and tell every node; producers and consumers find the new leader
by asking for fresh metadata and carry on.** The whole exchange takes seconds. The producer's job
during those seconds is to keep the sales it could not deliver and send them again, which it does
by itself, inside `message.timeout.ms`.

Find the leader of the partition the key `recife` goes to. Every `acks.py` run so far has printed
it: partition 1. The `describe` says who leads it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092,localhost:9093 --describe --topic sales
```

@@BEFORE@@

## Kill the leader, mid-stream

In the second shell, start a producer that sends a hundred sales at five a second, twenty seconds
in all:

```
ubuntu@stream:~/work$ python acks.py --acks all --count 100 --rate 5
```

A few seconds in, in the first shell, kill the leader of partition 1 with `-9`, which ends the
process with no chance to say goodbye, as a power cut would. Use the number your `describe`
printed:

@@KILL@@

When the producer finishes, the second shell shows:

@@PRODUCED@@

@@AFTER@@

## The node comes back

Start it again. It has a log that stops where it died, so it starts as a follower, fetches what it
missed, and rejoins the ISR:

@@BACK@@

Every ISR is whole again, and the leaders are not where they started. **A returning node does not
take its leadership back.** That leaves the load uneven: one node leads two partitions, and takes
twice the writes and twice the reads of another.

The first node in each `Replicas` list is the partition's **preferred leader**, and Kafka moves
leadership back to it in two ways. The broker does it on its own: with
`auto.leader.rebalance.enable=true`, the default, it checks every
`leader.imbalance.check.interval.seconds`, 300 by default, and moves leaders back when a node's
share is off by more than ten per cent. Or you ask for it at once:

```
ubuntu@stream:~/work$ kafka-leader-election.sh --bootstrap-server localhost:9092 --election-type preferred --all-topic-partitions
```

@@PREFERRED@@

## What it cost

Nothing that was acknowledged. A hundred sales sent, a hundred delivered, at a hundred consecutive
offsets, so none was written twice either. What the failure cost was **time**: for a few seconds
the partition had no leader, and the sales sent in those seconds waited in the producer's memory.
A consumer of the partition would have seen the same pause. That is the price of replication done
right, and it is measured in seconds because the controllers wait a few seconds of silence before
they declare a node dead: long enough not to fail over on every slow heartbeat, short enough that
a till never notices.
