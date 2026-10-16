---
title: What a shuffle costs
version: 1
---

**A shuffle is paid in three currencies: disk, network and memory.** Each task of the stage before
it sorts or hashes its rows by the destination partition and writes them to its executor's local
disk, in one file. Each task of the stage after it fetches its share from every one of those files,
over the network on a real cluster, and merges what it fetched in memory, spilling to disk if it
does not fit.

The cost scales with the bytes that cross, and those depend less on the input than on the key. The
two groupings of section 02 read the same 24 million rows:

| | distinct keys | shuffle write |
|---|---|---|
| by kind | 4 | 0.0 MiB |
| by visitor | 1,729,141 | 34.6 MiB |

**Partial aggregation is why.** Each of the 15 reading tasks counts its rows per key before writing,
the `partial_count` of lesson 6. With four kinds, each task writes four rows. With 1.7 million
visitors, spread over all of the year, each task meets a large share of them and writes a row for
each: the partial count barely shrinks anything. **A grouping by a key with few values is almost
free to shuffle; a grouping by a key with many values pays for nearly every row.**

On this machine 34.6 MiB crosses in under a second, because "the network" is memory. On a cluster
of separate machines with a 10-gigabit network, about 1.2 GB a second at best, the same shuffle at a
thousand times the data, 35 GB, takes half a minute just to cross, if nothing else uses the network.
That is the slowness lesson 1 said the lab cannot show, and the reason the rest of this lesson and
the next are about making shuffles smaller or avoiding them.
