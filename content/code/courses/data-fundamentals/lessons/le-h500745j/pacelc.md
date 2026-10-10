---
title: PACELC, the trade-off on an ordinary day
version: 1
---

**CAP only speaks while the network is broken, and most days it is not; PACELC adds the trade-off
that is paid the rest of the time.** The name is the sentence it stands for: if there is a
Partition, choose Availability or Consistency; Else, choose Latency or Consistency. Daniel Abadi proposed it in 2010 and published it in 2012, arguing that the
second half shaped real databases more than the first.

## Why the second half exists

Go back to the middle row of the table in section 04. A write that must be
acknowledged by a majority waits for a message to reach another machine and come back. Nothing is
broken; that wait is simply what being sure costs. If the other machines are in the same building,
the wait is short. If one copy is in another city so that a fire cannot take all of them, every
write pays the round trip to that city.

The alternative is to answer from the nearest copy straight away and let the others catch up. That
is faster on every request, and it gives up exactly what an AP system gives up during a partition:
for a while, two readers can see two values. **So the choice CAP describes during a partition is
being made, in a milder form, on every request.**

## The four combinations

Each letter pair is a separate choice, so there are four kinds of system. Abadi used them to sort
real ones.

| | during a partition | on an ordinary day | an example from Abadi's sorting |
|---|---|---|---|
| **PA/EL** | answer | answer fast, from the nearest copy | Dynamo and Cassandra, as they are set up by default |
| **PC/EC** | refuse | wait for the copies to agree | distributed databases with full transactions, and HBase |
| **PA/EC** | answer | wait for the copies to agree | MongoDB, as it was in 2012 |
| **PC/EL** | refuse | answer fast | PNUTS, a Yahoo! system |

The first two rows are the consistent pairs: a system that values agreement enough to refuse
during a cut usually values it enough to wait for it on a normal day, and the reverse. The other
two exist, and their reasoning is specific to the system that made them.

## Usually a setting, not a label

Many systems let the caller choose per request. **Cassandra** takes a *consistency level* with
every read and write: `ONE` answers when a single copy has, `QUORUM` waits for a majority. Lesson
9's arithmetic applies directly — with three copies, quorum writes and quorum reads overlap, and the
read sees the write. **DynamoDB** reads are eventually consistent unless the request asks for a
strongly consistent read.

That is why the four labels describe a default rather than a product. The useful question about a
system is not "which letters is it" but **"what does each operation I care about wait for, and
what does it return when the network is cut?"** Section 08 asks it of seven of them.
