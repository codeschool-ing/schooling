---
title: Four misreadings of CAP
version: 1
---

CAP is quoted more often than it is read, and four misreadings account for most of what goes wrong when
it is used to argue for a design.

**"Pick two of three."** As the section on partitions showed, P is not on the menu for a distributed
system. The real statement is narrower: when partitioned, choose C or A. Brewer himself wrote in 2012,
twelve years after the conjecture, that "two of three" was misleading.

**"Our database is CP" or "AP", as a property of the product.** The choice is made by configuration and
often per request. The lab's PostgreSQL was CP and AP within ten minutes, by one setting. DynamoDB and
Cassandra let each read or write say how many replicas must answer, the subject of the next section.
**A system's position on CAP is a property of how it is used**, and two tables in one database can sit
on opposite sides.

**"C" means the C of ACID.** ACID's consistency means a transaction leaves the database obeying its
constraints, a foreign key, a `CHECK`. CAP's means every read sees the latest write, across copies. A
single-node database is ACID-consistent with no replicas at all; a replicated one can be ACID-consistent
on each node and still return an old value from the standby.

**"Availability" means uptime.** CAP's A asks that every non-failing node answer every request. A
system that refuses writes during a partition is not "A" in CAP's sense and may still have excellent
uptime in the operational sense, because partitions are rare. And a system that is "A" can be slow
enough to be useless. Availability as a number of nines is a different, operational idea, which `scale`
lesson 11 is about.

## What CAP is good for

Stripped of those, the theorem leaves one useful question for any piece of data that lives on more than
one machine: **when the copies cannot talk, should the system refuse, or answer and risk being wrong?**
Asked per piece of data, by people who know what a wrong answer costs, it produces good designs. Asked of
a whole system, or of a product, it produces arguments.
