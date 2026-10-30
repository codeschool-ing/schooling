---
title: Four meters on every storage account
version: 1
---

**A Blob Storage bill has four meters, and capacity is only one of them.** Capacity counts gigabytes
kept for a month. Operations count requests, priced per 10,000. Data retrieval counts gigabytes read
back out of the cool, cold and archive tiers. Bandwidth counts the bytes that leave. People estimate
an account by its size, multiply by the price per GB-month, and are right about the account and wrong
about the bill, because an account that is read a lot is mostly paid for by the reading.

**This section is taught from Microsoft's pricing pages for Blob Storage and for bandwidth, and
nothing in it was run.** No emulator meters anything, and the price sheet of lesson 1 could not be
read from the machine this course was recorded on. Every sum below uses round prices that say they
are illustrative, as lesson 1 explained.

## The four, and their units

| meter | unit | what moves it |
|---|---|---|
| capacity | GB-month, per tier and per redundancy | how much is kept, in which tier, with how many copies |
| operations | 10,000 operations, per tier, by class | every request: a write, a read, a listing |
| data retrieval | GB, in cool, cold and archive | bytes read back from a tier that is cheap to keep |
| bandwidth | GB leaving, by destination | bytes sent to the internet or to another region |

**Operations are priced by class, and the classes do not cost the same.** Microsoft's sheet groups
them as write operations, read operations, list and create container operations, and all other
operations, with a line for each class in each tier. Writes cost more than reads. Listing has a line
of its own and is not priced like a read. And the cooler the tier, the more each operation costs,
which is lesson 4's trade seen from the other side: cool, cold and archive are cheap to keep because
they charge for being touched.

**Data retrieval is a second charge on the same read.** Reading a gigabyte from the cool tier pays
for the read operations and then for the gigabyte; reading it from hot pays only the operations.
Archive adds the rehydration of lesson 4 before any of it.

**Data coming in is free.** The bandwidth page charges nothing for bytes transferred into Azure, which
is why an account fills without anybody noticing the cost and empties expensively. The write
operations that put the bytes there are still billed: inbound bytes are free, inbound requests are
not.

An account with geo-redundant replication, the GRS and GZRS of lesson 1, has a fifth line:
geo-replication data transfer, per GB copied to the paired region. Every write is copied, so an
account that is rewritten often pays for its second region on every rewrite.

## The size of an operation against the size of a gigabyte

The units hide the comparison that matters. At this lesson's illustrative prices, 0.02 USD to keep a
GB in hot for a month and 0.004 USD per 10,000 reads, one gigabyte-month buys 0.02 / 0.004 × 10,000
= 50,000 reads. So **when a gigabyte's blobs are read more than about 50,000 times a month in all,
the reads cost more than keeping them**. For one file of 1 GB that never happens. For a gigabyte made
of 262,144 blobs of 4 KB each, reading every blob once is 262,144 reads, 0.10 USD, five times the
month's storage.

An operation is priced per operation whatever its size, and capacity is priced per byte whatever the
number of blobs. The next two sections follow from those two sentences.

## Reading the real lines

The price sheet of lesson 1 prints them. In `~/azure`, with the network:

```sh
python prices.py Storage Hot
python prices.py Bandwidth
```

**Neither was run while the course was recorded**, for the reason lesson 1 gives, so there is no
output here to compare yours with. Azure files transfers as a service of their own, which is why the
second line asks for `Bandwidth` and not `Storage`; if it prints nothing for `brazilsouth`, the
bandwidth pricing page is the source to read instead. Read the unit of every line before its price:
capacity is per GB-month, operations per 10K, retrieval and bandwidth per GB. On a real subscription
the same meters come back as lines of the invoice, which `azure-foundations` lesson 14 reads.
