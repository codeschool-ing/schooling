---
title: Sentinel or Cluster
version: 1
---

The two are often presented as a basic and an advanced version of the same thing. They are not. **Sentinel
makes one dataset highly available; Cluster splits a dataset across machines and makes each part
highly available.** The question that picks one is whether the data and its write rate fit on one
machine, not how serious the project is.

## Side by side

| | Sentinel | Cluster |
| --- | --- | --- |
| what it solves | the primary's machine dying | the dataset or its writes outgrowing one machine, and a primary dying |
| where writes go | one primary, for everything | one primary per slot range |
| processes in the lesson | 3 Redis + 3 Sentinel | 6 Redis, no Sentinel |
| multi-key commands, transactions, Lua | on any keys | only on keys in one slot; hash tags to arrange it |
| databases `SELECT 1` to `15` | available | only database 0 |
| what the client needs | ask a Sentinel for the primary | follow `MOVED` and know the slot map |
| failover | Sentinels vote, by quorum | the primaries vote, by majority |
| losing acknowledged writes | possible, as the previous section showed | possible, for the same reason |
| adding capacity | a bigger machine | more primaries, moving slots to them |

## What each costs

**Sentinel costs processes and a client that knows to ask.** Three Sentinels are small, but they are
three more things to run, to place on separate machines and to watch; two Sentinels on the same
machine as the primary vote as one when that machine dies. And every client must be configured with
the Sentinels' addresses rather than the primary's, or the first failover leaves it writing to
nothing.

**Cluster costs the data model.** Every place the application touches two keys at once, a transaction,
a Lua script, an `MGET` over customers, either keeps its keys in one slot or stops working. That is a
modelling decision of the kind lessons 3 and 4 made, taken before the first deployment, because moving
existing keys under a new hash tag is a migration. Resharding, moving slots to a new primary, is done
online with `redis-cli --cluster reshard`; it moves keys while clients are served, and it takes time
proportional to the data moved.

## For the shop

The shop's Redis holds stock counters, carts, sessions and the streams of lesson 12: a few gigabytes
at most, a write rate one server handles comfortably. **That is Sentinel's case.** Cluster would
split carts and counters across nodes, forbid the transactions that touch both, and buy capacity the
shop does not need. The day one machine stops being enough is the day to model for slots, and what lesson
10 says about a shard key chosen too early applies to a hash tag as well.

And whichever is chosen, the previous section stands: **an acknowledged write can be lost in a
failover.** Data that must not be lost goes to a store whose replication waits for a majority, such as
the MongoDB replica set of lesson 9 with its majority write concern, or the relational database the
shop already has.
