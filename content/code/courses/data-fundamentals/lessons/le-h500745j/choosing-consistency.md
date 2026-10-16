---
title: Choosing consistency, and what refusing costs
version: 1
---

**A system that chooses consistency answers only when it can be sure the answer is current, and on
the wrong side of a cut that means answering with an error.** People call such a system CP. The
name sounds like a property of the whole system, but what it describes is a rule each node
follows when it cannot reach enough of the others.

## How a CP system knows it may speak

The rule in `replicas.py` was a majority, and real systems use the same idea. Lesson 9's quorums
said that a write acknowledged by a majority and a read that asks a majority must overlap in at
least one node, so the read sees the write. A CP system adds a second use of the majority: only
one group of nodes can hold one at a time, so only one group can accept writes.

Keeping a group of machines agreeing on the order of every write, through crashes and cut links,
is called **consensus**, and two algorithms for it are worth recognising by name. **Paxos**, from
Leslie Lamport, is the older one. **Raft**, published in 2014, was designed to be easier to
understand and to build correctly. etcd, the store Kubernetes keeps its state in, runs Raft.
ZooKeeper runs a protocol of its own, ZAB, built on the same majority idea. Neither algorithm is
this course's to teach; what matters here is what using one costs.

## What it costs

Refusing during a partition is the cost everyone sees. Two others are paid on ordinary days, and
they are usually the larger bill.

| cost | when it is paid | at Roda Livre |
|---|---|---|
| the minority side refuses | only during a partition | the customer at `n3` cannot return her bicycle in the app |
| every write waits for a majority to acknowledge it | on every write, partition or not | each unlock waits for a second machine to answer |
| losing the leader stops writes until a new one is chosen | each time the machine coordinating writes fails | a pause in which no bicycle can be unlocked |

The second row is the one the theorem does not mention, because the theorem only speaks during a
partition. Section 06 gives it a name.

## Where refusing is right

**Choose consistency where two different answers would be worse than no answer.** The test is to
imagine both sides of a cut saying yes at once, and ask whether that can be undone.

- **A bicycle can be unlocked for one customer.** If `B017` were unlocked for two people on two
  sides of a cut, the second one finds an empty dock and a charge for a ride they never took.
- **A payment is taken once.** Charging twice, or recording a charge that never happened, is an
  incident with a customer on the phone.
- **One machine is in charge.** When a group of machines elects one to coordinate the others,
  two leaders at once, called a *split brain*, is the failure the election exists to prevent.

A refusal is also the kind of failure lesson 1 called the good kind. It is loud: the client gets
an error it can retry, and lesson 9's retries with an idempotent write make that retry safe. A
system that chose availability for a payment would not fail loudly. It would succeed twice.
