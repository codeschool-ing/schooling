---
title: Graph and time series, described rather than installed
version: 1
---

Two more families are worth knowing by the questions they answer, and **this course does not install
either of them**. The reason is the course's subject rather than the products. The operations it
teaches, from replication to repair, are learnt on the three servers you already have, and each
further server would cost the lab memory without a new operational lesson to show for it. Nothing below was run. The products named are examples, and nothing in a later lesson depends
on any of them.

## Graph: questions that follow links

The question a graph store is built for has a **variable number of hops**. "Customers who bought
what Ana bought also bought..." is two hops from Ana: to her products, then to the other customers
of those products, then to what they bought. "Who is within three introductions of Ana" is three.
"Is there any chain of shared cards and addresses between these two accounts" has no fixed length at
all, and it is the question fraud teams ask.

In a relational database each hop is a join, and a variable number of hops is a recursive query.
That works, and up to two or three hops over indexed tables it is often fast enough. The cost is
that each hop is an index lookup over a whole table, so a deep traversal does work in proportion
to the tables it passes through. **A graph store keeps each node's links next to the node**, so
following a link is a pointer rather than a search, and a traversal costs in proportion to what it
touches. The order of the figure in the first section becomes nodes, Ana, order 1001, the cable and the
mouse, and edges between them that carry data of their own, like the quantity.

Neo4j is the best-known product, queried in a language called Cypher. What to watch for, if a
problem seems to want one: **the question is about paths, not about totals.** Summing every order
of September is a scan in any store, and a graph store is not the fast one at that.

## Time series: questions about measurements over time

A time series is a sequence of measurements, each with a timestamp: the response time of the shop's
checkout, sampled every ten seconds, is 8,640 points a day for one server. The data has a shape a
general database does not assume:

| | in a time series | in the shop's orders |
|---|---|---|
| writes | appended, nearly always at the current time | inserted, then updated as the order moves |
| a point once written | almost never changed | changed by every status update |
| reads | a time range, aggregated: the average per minute last Tuesday | one order, or one customer's orders |
| old data | **downsampled**, then dropped by a **retention** policy | kept for years, for accounting |

The last row is the one that decides. A year of ten-second points is useless as points and useful
as one-minute averages, so a time-series store rolls old data up into coarser intervals and deletes
the rest on a schedule. A general database can be made to do that, with a job that someone has to
write and keep running.

Three products show the range. **TimescaleDB is an extension to Postgres**: tables stay tables and
SQL stays SQL, and time-partitioned storage, rollups and retention are added underneath. InfluxDB
is a database built for nothing else. Prometheus collects metrics by asking each service for them
at an interval and keeps them for a set retention, which makes it monitoring software as much as a
database. Lesson 20 reads the metrics the three databases of this course expose, whatever collects
them.

## Picking by the question

| family | the question it is built for | the sign you need it |
|---|---|---|
| document | "give me this whole thing" | the application reads and writes one aggregate at a time |
| key-value | "give me the value under this name" | every access starts from a known key |
| wide column | "give me this partition's rows, in order" | huge write volume, and reads you can list in advance |
| graph | "what is connected to this, and how" | the hard queries are paths of unknown length |
| time series | "what happened in this interval" | timestamped measurements, old data worth less every day |

Lesson 22 comes back to this table with the question every one of these rows skips: whether the
relational database you already run answers it well enough.
