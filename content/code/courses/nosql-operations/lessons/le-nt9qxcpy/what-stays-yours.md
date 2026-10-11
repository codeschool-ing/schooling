---
title: What stays yours
version: 1
---

Everything above the line is a decision about **your data and your money**, and the provider will
carry out whichever one you make, including the wrong one. A managed MongoDB accepts a shard key
that sends every write to one shard; a managed Cassandra stores a partition of a gigabyte; a managed
Redis evicts the sessions of logged-in customers if that is the policy it was given. None of those
is an outage the provider is responsible for, and none will appear on its status page.

## The list, with the lesson that taught each

| still yours | why the provider cannot decide it | lesson |
|---|---|---|
| the data model: documents, partitions, which data is duplicated | it follows from your queries, which only you know | 3, 4 |
| indexes | an index is a trade between the reads you run and the writes you pay for | 7 |
| the shard key | it is fixed at creation, and moving it later is a migration of everything | 10 |
| write concern, read preference, consistency levels | each is a choice per operation between latency and a guarantee | 9, 17 |
| the eviction policy, and whether Redis is a cache or a database | the same full memory is fine for one and data loss for the other | 14 |
| capacity, and the bill it produces | the provider sells you more; deciding you need it is yours | 20 |
| restore drills | a backup nobody has restored is a hope, and the provider's is no exception | 11 |
| who has access, from where | the provider enforces the rules; it does not know who should be in them | |

**The bill deserves a sentence of its own.** On your own machines, a database that grows costs a
disk you buy once. On a managed service, almost every axis is a line on the invoice: storage,
memory, operations or capacity units, backup storage beyond the free allowance, and data leaving
the provider's network. A badly modelled table that reads a thousand rows to return ten (lesson 18)
is a slow query on your own hardware and a monthly cost on a service that charges per read.

## Restore drills, when somebody else takes the backup

The provider's backups are real, and they are also the one part of the service you cannot see
working until you use it. **A restore drill on a managed service answers three questions** the
documentation cannot: how long a restore of your actual data takes, what the restored copy is
missing (users and roles, indexes still building, settings that live outside the data), and who in
your team knows where the button is.

Most services restore into a new instance beside the old one rather than over it. Do exactly that,
on a calendar, point a copy of the application at the result, and write down the time it took. The
number goes into the runbook, and it is the number the next section's exit plan needs as well.

## Access

A managed database is reachable over a network you do not own, by default from more places than
the containers of this course, which had no published port at all. **The three settings that keep
it private** are on every provider under different names: the database reachable only from your
private network (a VPC peering or a private endpoint) rather than from the internet; TLS required
on every connection; and an account per application and per person, each with the least it needs,
so that a leaked password opens one door. The provider writes an audit log of who connected; reading
it is yours.
