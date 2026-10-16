---
title: Replication, and the in-sync replicas
version: 1
---

**A Kinesis shard is replicated by AWS and you never see the copies; a Kafka partition's copies are
part of its configuration.** Each partition has a **replication factor**, the number of brokers that
hold a copy of it. One of those copies is the **leader**, which takes every write and, by default,
every read; the others are **followers**, which fetch from the leader and stay as close behind it as
they can. The followers that are close enough are the **in-sync replicas**, the ISR, and they are
the only ones allowed to become leader when the leader's broker dies.

The single broker of the last section can show the vocabulary and not the behaviour. The
`--describe` of the topic said `Leader: 1  Replicas: 1  Isr: 1` for every partition: broker 1 holds
the only copy, it leads, and it is in sync with itself. Asking for three copies on one broker fails,
with the reason in the message:

```
ana@laptop:~/aws/kafka_2.13-4.4.0$ bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic orders-rf3 --partitions 3 --replication-factor 3
Error while executing topic command : Unable to replicate the partition 3 time(s): The target replication factor of 3 cannot be reached because only 1 broker(s) are registered or some brokers have all their log directories cordoned.
[2026-10-16 13:27:54,168] ERROR org.apache.kafka.common.errors.InvalidReplicationFactorException: Unable to replicate the partition 3 time(s): The target replication factor of 3 cannot be reached because only 1 broker(s) are registered or some brokers have all their log directories cordoned.
 (org.apache.kafka.tools.TopicCommand)
```

**On MSK the brokers are spread across Availability Zones, and so are the copies.** A cluster of
three brokers in three zones, with a replication factor of 3, holds every partition once in every
zone, with the leaders spread so that each broker leads a third of them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three brokers, one in each of three Availability Zones, holding a topic of three partitions with a replication factor of 3. Every broker holds a copy of every partition. Broker 1 leads partition 0, broker 2 leads partition 1 and broker 3 leads partition 2; the other two copies of each partition are followers that fetch from its leader. Losing one zone leaves two copies of every partition.\" data-fig=\"l22-replicas\"><rect x=\"30.0\" y=\"20.0\" width=\"200.0\" height=\"175.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"50.0\" y=\"50.0\" width=\"160.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">broker 1</text><rect x=\"65.0\" y=\"82.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">partition 0, leader</text><rect x=\"65.0\" y=\"114.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partition 1, follower</text><rect x=\"65.0\" y=\"146.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partition 2, follower</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"175.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"280.0\" y=\"50.0\" width=\"160.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">broker 2</text><rect x=\"295.0\" y=\"82.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partition 0, follower</text><rect x=\"295.0\" y=\"114.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">partition 1, leader</text><rect x=\"295.0\" y=\"146.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partition 2, follower</text><rect x=\"490.0\" y=\"20.0\" width=\"200.0\" height=\"175.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"590.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"510.0\" y=\"50.0\" width=\"160.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">broker 3</text><rect x=\"525.0\" y=\"82.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partition 0, follower</text><rect x=\"525.0\" y=\"114.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">partition 1, follower</text><rect x=\"525.0\" y=\"146.0\" width=\"130.0\" height=\"24.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">partition 2, leader</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one zone lost: every partition still has two copies</text></svg>", "caption": "Replication factor 3 over three zones: a copy of every partition in every zone, and the leaders spread."}
```

## What makes a write durable

**A write is as safe as the setting that acknowledged it.** The producer's `acks` decides when the
leader answers: `acks=0` is not waiting at all, `acks=1` is the leader alone having written it, and
`acks=all`, the default since Kafka 3.0, is every in-sync replica having it. The topic's
`min.insync.replicas`, shown as `1` in the `--describe` above, decides how few in-sync replicas may be
left before the leader refuses writes rather than accept them with too few copies.

The combination that loses nothing when one zone fails is replication factor 3, `min.insync.replicas`
2 and `acks=all`. A write is then acknowledged only once two zones hold it, any one zone can be lost,
and if two are lost the partition stops taking writes instead of taking them on a single copy. With
`min.insync.replicas=1`, the default here, an acknowledged write can live on one broker only for a
moment, and that broker's failure in that moment loses it. **This is the durability Kinesis gives you
without a setting**, and with Kafka it is a decision somebody has to make and check.

None of this was run, because one broker has no followers; it comes from Kafka's documentation, and
it is the same on MSK, whose default configuration for a cluster in three zones sets a replication factor of 3 and a `min.insync.replicas` of 2.
The two things a single broker did show are the two worth checking on any cluster: what `--describe`
prints for `Replicas` and `Isr`, and what `min.insync.replicas` is set to.

**Replication is also traffic, and on MSK it is free.** Every record written to a partition with a
replication factor of 3 crosses to two other zones. AWS does not charge for that traffic between the brokers of one MSK cluster. It does charge, at the zone-crossing price of `aws-foundations` lesson 1,
for a producer or a consumer in one zone talking to a leader in another, which the last section of
this lesson puts a number on.
