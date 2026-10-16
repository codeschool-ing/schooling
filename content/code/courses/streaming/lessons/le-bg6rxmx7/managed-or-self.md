---
title: Running it yourself, or renting it
version: 1
---

**A managed Kafka service sells you the same broker, operated by somebody else, and prices it on
something you can measure.** What it measures is the important part, because the same pipeline can
be cheap under one pricing model and expensive under another. This section names no prices: they
change every year, they differ by region, and a number printed in a course would be wrong before you
read it. What lasts is the shape.

## What the services charge for

The offers differ in detail, and almost all of them are built from a few units:

| unit | what makes it grow | who it favours |
|---|---|---|
| broker or cluster hours | the size and number of machines, all day | steady, predictable traffic |
| throughput: data in and out | messages times bytes, times readers on the way out | small clusters with little traffic |
| partition hours | every partition that exists, busy or idle | few large topics |
| storage, per gigabyte-month | retention times copies, sometimes billed once for all copies | short retention |
| network | traffic between zones and out of the provider | single-zone clients, nearby consumers |

A serverless offer bills mostly on throughput and partitions, with no machines to choose; a
provisioned one bills on machine hours and lets you fill them. **The retention arithmetic of this
lesson is the input to all of them.** Messages a day and bytes a message give the throughput, the
days and copies give the storage, and the number of consumer groups multiplies the traffic out.

## What running it yourself costs

The machines, their disks and the network between them, which is the same arithmetic. And the part
that does not show on an invoice:

- **Somebody on call**, because a broker fails at night as easily as by day (lesson 16's list is what
  wakes them).
- **Upgrades**, done one broker at a time without stopping the stream; Kafka 4 alone removed
  ZooKeeper and changed the consumer protocol.
- **Capacity**, added before it is needed, and partitions moved onto new brokers when it is.

A small team running one cluster with steady traffic often finds the managed service cheaper once
those hours are counted. A large platform with a team that operates Kafka anyway often finds the
reverse. Neither is a rule, and the comparison has to be made with your own throughput.

## Questions that change the answer

- **How many readers?** Throughput out is billed per byte read, and every consumer group reads the
  whole topic. Five groups on one topic is five times the egress.
- **How long is retention?** A month of retention on a service that bills storage per copy is three
  times the arithmetic's one-copy line.
- **Where do the consumers run?** A consumer in another region or another cloud pays to bring every
  byte across.
- **How many partitions?** A model that charges per partition hour makes a hundred partitions created
  "for later" a bill today; lesson 3's advice to choose partitions deliberately has a price on it.
