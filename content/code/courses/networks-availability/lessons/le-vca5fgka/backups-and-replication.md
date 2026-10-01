---
title: Backups, replication, and what each one saves
version: 1
---

The RPO of a system is set by one thing: how the data is copied somewhere else, and how often. There are
two families of copy, and the common mistake is to believe the modern one replaces the old one. **A
replica copies mistakes as faithfully as it copies data.** A `DELETE` without its `WHERE` reaches every
replica within moments of reaching the primary, and only a copy taken before it can bring the rows back.

## Backups

A backup is a copy of the data as it was at one moment. Its RPO is the gap between backups: with one a
night, a failure just before the next one loses almost a day of writes. Its RTO is the time to find the
right copy, restore it and check it, which grows with the size of the data and is measured in hours for
anything large.

What a backup protects against is exactly what replication does not: deletion, corruption, a bad release
that rewrote a column, ransomware that encrypted the primary and everything connected to it. The usual
rule is **3-2-1**: three copies of the data, on two different kinds of storage, one of them off-site.
Many teams add that one copy be offline or immutable, since anything an attacker can reach from the
primary, an attacker can also encrypt.

**A backup that has never been restored is not a backup; it is a hope.** Restoring one on a schedule is
the only way to know it works, and the only way to know the RTO, because the real restore time is the
one measured, not the one estimated.

## Replication

A replica is a second copy kept up to date continuously. How closely it follows is the choice that sets
the RPO:

- In **synchronous** replication, the primary confirms a write to the application only after the replica has it too.
  Nothing confirmed is ever lost, an RPO of zero. Every write pays a round trip to the replica, so
  distance costs: light in fibre covers about 200 km a millisecond, and a replica 1000 km away adds about
  10 ms to every write.
- In **asynchronous** replication, the primary confirms at once and sends the change on afterwards. Writes are fast, and
  the RPO is whatever the replica was behind at the moment of the failure, the **replication lag**:
  usually seconds, and much more when the primary is busy, which is when failures tend to happen.

| copy | RPO | RTO | protects against |
|---|---|---|---|
| nightly backup | up to 24 hours | hours | hardware loss, site loss if kept off-site, deletion, corruption, ransomware if offline |
| asynchronous replica | the lag, seconds or more | minutes | hardware loss, site loss if far enough away |
| synchronous replica | zero | seconds to minutes | hardware loss, site loss within the distance it tolerates |

Promoting a replica when the primary fails brings back lesson 14's hardest problem. If the old primary
is not dead but only cut off, and it keeps accepting writes while the replica is promoted, there are two
primaries and **two diverging copies of the truth**: split brain, with data. That is where the quorum and
the fencing of lesson 14 stop being theory. A database cluster that fails over automatically needs a
third vote to decide who may be primary, and a way to make sure the old one has stopped.

So a serious design uses both families: replication for the RTO of the failures that are about hardware
and places, backups for the RPO of the ones that are about mistakes, and a restore drill to prove the
numbers written in the plan.
