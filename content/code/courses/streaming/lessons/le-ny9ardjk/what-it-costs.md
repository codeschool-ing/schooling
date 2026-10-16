---
title: What replication costs, and what this lab cannot show
version: 1
---

**A replication factor of 3 stores every byte three times, sends every byte across the network at
least three times, and only protects against the failures that the three copies do not share.** The
first two are a bill; the third is a design decision that this lab, on one machine, cannot
demonstrate.

## Disk and network

The `wc -c` in the section on leaders and followers measured the first: the same segment, with the
same number of bytes, once per node. Three hundred sales took **32,443 bytes** on each node, 97,329
in all. Every capacity sum for a Kafka cluster has the replication factor in it, and lesson 17 does
that arithmetic for Ponto Final.

The network is the less obvious cost. Each record crosses the network once from the producer to the
leader, and once more **for each follower** that fetches it, so a replication factor of 3 puts two
extra copies of every write on the wire between brokers, before any consumer reads anything. A
replication factor of 3 earns its keep in a cluster spread over three data centres or cloud zones,
and there that traffic is priced as traffic between zones. The public clouds charge for it, and it
is often the largest item on a streaming bill after the machines themselves.

## Failure domains

Three copies protect against the loss of one or two of them only if the three do not fail together.
Three brokers in one rack share a power supply and a switch; three brokers in one cloud zone share
that zone's outages. The setting that spreads them is **`broker.rack`**: give each broker the name
of its rack or zone, and Kafka places the replicas of each partition on different racks when it
creates a topic. With the brokers' `replica.selector.class` set to Kafka's rack-aware selector,
consumers can then be given **`client.rack`** to read from the follower in their own zone instead
of crossing to the leader, the follower fetching mentioned in the section on leaders and followers.

**Nothing in this lab is a real failure domain.** The three nodes are three processes on one
virtual machine, with one disk and one power supply: losing the machine loses all three. Every
failure in this lesson was a process ending, which is the kind of failure replication handles, and
none was a disk, a rack or a zone, which are the kinds it is for. The behaviour you saw is the
same; the protection only exists on separate hardware.

## Choosing a replication factor

| replication factor | `min.insync.replicas` | survives, still writing | used for |
|---|---|---|---|
| 1 | 1 | nothing | a lab, or data that can be rebuilt from elsewhere |
| 2 | 1 | one failure, but then a single copy takes writes | rarely a good trade |
| 3 | 2 | one failure, with every write on two disks | the production default |
| 5 | 3 | two failures | data whose loss would be a disaster, at a high price |

**A replication factor of 2 is the trap in that table.** With `min.insync.replicas=2` it stops
taking writes when either node is down, which is every maintenance window; with 1, it takes writes
on a single disk whenever a node is down. Three is the smallest number with an answer that is
neither.
