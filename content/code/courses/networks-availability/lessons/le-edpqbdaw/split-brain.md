---
title: Split brain, and why two cannot vote
version: 1
---

The worst failure of a redundant pair is not both machines dying. It is **both machines alive, each
believing the other is dead**. It happens when the link that carries the heartbeats breaks while the
machines themselves are fine. Each stops hearing the other, each concludes it is alone, and each takes
over. This is called **split brain**.

For two routers sharing a virtual address, split brain means two machines answering for one address.
Hosts' ARP entries swing between two hardware addresses and traffic goes to whichever answered last. It
is ugly, and it ends the moment the link comes back. VRRP, lesson 15's protocol, is partly protected by
where it sends its heartbeats: over the very LAN it serves. A break that splits the two routers
usually splits the hosts as well, and each half keeps a gateway that works for it.

For anything that holds data, a pair of database servers or file servers, split brain is far worse.
**Both sides accept writes, and the two copies drift apart.** When the link returns there are two
versions of the truth, and nothing can merge an order recorded on one side with a refund recorded on
the other without a person deciding which one wins.

## A majority, or nothing

A pair cannot solve this by itself, because from inside each half the two situations look identical:
"my partner died" and "the line to my partner died" both arrive as silence. The way out is a
**quorum**. A machine may act only while it can see a majority of the voters. With three voters, a side
that sees two carries on and a side that sees only itself stops. Both halves of a split can never hold a
majority at once, so at most one of them acts.

| voters | a majority is | failures it survives |
|---|---|---|
| 2 | 2 | 0 |
| 3 | 2 | 1 |
| 4 | 3 | 1 |
| 5 | 3 | 2 |

The table explains a habit that looks like superstition: **clusters have odd numbers of members**. A
fourth voter survives no more failures than three do; it only adds a machine that can break. Two voters survive none. That is why a two-node cluster that cares about its data adds a third vote that does no work: a **witness**, often a small machine or a cloud service in a third place.

The other tool is **fencing**. Before taking over, the survivor makes sure the other really is off, by
cutting its power through a managed power strip or cutting its access to the shared storage. The
clustering world gives this a blunt name, STONITH, "shoot the other node in the head". It sounds
drastic, and it is the one way to be certain rather than hopeful that only one side is writing.

The VRRP and keepalived pairs in lessons 15 and 16 have neither quorum nor fencing, on purpose. For
routers and balancers that hold no data, the price of a short split brain is a few confused seconds, and
that is an accepted trade. For data it is not, and lesson 17 comes back to it with replication.
