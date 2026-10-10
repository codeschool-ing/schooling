---
title: Partitions are not optional
version: 1
---

The "pick two" reading invites a tempting choice: give up P, keep C and A, and build a "CA" system.
**For anything with more than one machine, that option does not exist.** Partition tolerance is not a
feature to choose; partitions are an event that happens to you, and the only choice is what the system
does when one does.

A partition is any situation in which some nodes cannot hear from others, and in practice it has many
causes besides a cut cable:

| cause | what it looks like from a node |
| --- | --- |
| a switch, a router or a cloud zone's network fails | the other node stops answering |
| a misconfigured firewall rule after a change | some traffic passes and some does not |
| a long garbage-collection pause on one node | that node is silent for seconds, then carries on as if nothing happened |
| a node overloaded to the point of not answering in time | indistinguishable from the network failing |
| a cluster stretched across two data centres | the link between them is a single slow thing that sometimes drops |

The third and fourth rows matter most, because nothing is broken in them. **A node cannot tell a
partition from a slow peer**: both look like silence until a timeout. So every distributed system, the
moment it waits on another machine, already has to decide what it will do when the wait runs out, and
that decision is its position on CAP whether anybody wrote it down or not.

## "CA" means one machine

A single PostgreSQL server is consistent and available in the sense above, and it has no partitions to
tolerate because it has no peers. That is a legitimate design, lesson 1's monolith with its one
database is one, and it is what "CA" actually describes. The moment a second copy exists, to survive the
loss of the first machine, the network between them can break, and the choice arrives.
