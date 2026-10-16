---
title: Kafka's model, in the words of lesson 20
version: 1
---

**Apache Kafka and Kinesis Data Streams solve the same problem with the same shape**: an ordered
log, split into pieces that are each ordered on their own, kept for a while and read by as many
readers as want it. MSK is AWS running Kafka for you, so the model to learn is Kafka's. The words
differ, and a few of the differences are real rather than vocabulary:

| Kinesis, lesson 20 | Kafka | what is different |
|---|---|---|
| stream | **topic** | nothing that matters |
| shard | **partition** | a partition lives on a broker you can name, a shard on machines you never see |
| sequence number | **offset** | an offset is a plain integer from 0, counted per partition |
| partition key | **key** | the key is hashed with murmur2 modulo the partition count, not MD5 into ranges |
| iterator and checkpoint | **committed offset of a consumer group** | the broker stores the position, not your program |
| retention, 24 hours to 365 days | **retention by time, by size, or both**, or for ever, or **compaction** | Kafka can keep the latest record per key and nothing older |

**The consumer group is the idea Kinesis does not have built in.** A group is a name, `fraud` or
`lake-copy`, shared by one or more consumer processes. Kafka hands each partition of the topic to
exactly one member of the group, and when a member joins or dies it moves partitions between the
members that are left; that is a **rebalance**. Each group keeps its own committed offset per
partition, on the broker, so two groups read the same topic independently, and a group that restarts
carries on from where it committed. In Kinesis that bookkeeping is the Kinesis Client Library's, which
keeps its leases and checkpoints in a DynamoDB table of your own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The topic orders with three partitions, read by two consumer groups. The group fraud has two members: the first is assigned partitions 0 and 1, the second partition 2, and each partition goes to exactly one member. The group lake-copy has one member, assigned all three partitions. Each group keeps its own committed offset per partition on the broker, so the two read the same records independently.\" data-fig=\"l22-groups\"><text x=\"20.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">topic</text><text x=\"70.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><rect x=\"205.0\" y=\"105.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 0</text><rect x=\"315.0\" y=\"105.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 1</text><rect x=\"425.0\" y=\"105.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 2</text><rect x=\"190.0\" y=\"95.0\" width=\"340.0\" height=\"56.0\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"20.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">group</text><text x=\"62.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">fraud</text><rect x=\"180.0\" y=\"30.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">member 1</text><rect x=\"420.0\" y=\"30.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">member 2</text><line x1=\"250.0\" y1=\"105.0\" x2=\"230.0\" y2=\"60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></line><line x1=\"360.0\" y1=\"105.0\" x2=\"230.0\" y2=\"60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></line><line x1=\"470.0\" y1=\"105.0\" x2=\"470.0\" y2=\"60.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></line><text x=\"20.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">group</text><text x=\"62.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">lake-copy</text><rect x=\"310.0\" y=\"195.0\" width=\"100.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">member 1</text><line x1=\"250.0\" y1=\"141.0\" x2=\"360.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></line><line x1=\"360.0\" y1=\"141.0\" x2=\"360.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></line><line x1=\"470.0\" y1=\"141.0\" x2=\"360.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></line><text x=\"560.0\" y=\"45.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offsets of fraud: one per partition</text><text x=\"560.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offsets of lake-copy: its own</text></svg>", "caption": "Within a group each partition has one reader; across groups every group reads everything."}
```

**Order is per partition, exactly as it is per shard**, and the same consequence follows: what is
ordered in practice is each key's records. Two differences make Kafka's version less forgiving.
The partition is `murmur2(key) mod N`, so **adding partitions to a topic moves keys**: a key that went
to partition 1 of 3 may go to partition 3 of 4, and its new records can be read before its old ones.
Kinesis's resharding keeps a key inside its parent's hash range and records the lineage, which is
what let lesson 20's consumer finish the parent first. And a topic's partitions can be added and
never removed.

**Retention can be a size as well as a time.** `retention.ms` keeps records for a period,
`retention.bytes` caps each partition's log at a size, and whichever is reached first deletes the
oldest **segment**, a file of the log, whole. With `cleanup.policy=compact` Kafka instead keeps, for
every key, at least the latest record, which turns a topic into a table: the current address of
every customer, say, kept for as long as the topic exists. Kinesis has no equivalent; its records
expire by age alone.

The next section runs a broker on your own machine and does all of this for real. MSK does not
change any of it: an MSK cluster is Kafka brokers, and the same commands work against them.
