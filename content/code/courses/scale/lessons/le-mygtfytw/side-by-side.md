---
title: The five, side by side
version: 1
---

Five databases in one lesson is too many to keep in your head as products. Kept as answers to the
questions of lesson 4, they reduce to a table, and every row of it is something you saw in this
lesson:

| | its unit | where a row lives | the fast question | the refused or expensive one | seen here |
|---|---|---|---|---|---|
| **MongoDB** | a document | a shard, by a shard key, when sharded | one document, or a filter on an indexed field | the same filter without an index; a fact copied into many documents | `COLLSCAN` of 100 for 34; 33 documents rewritten for one rename |
| **DynamoDB** | an item | a partition, by the hash of the partition key | one partition key, a range of its sort key | anything without the partition key | a query by sort key refused; a scan reading 5 to return 3 |
| **Cassandra** | a row in a partition | a node, by the token of the partition key | one partition, in clustering order | a filter on a column outside the key | `ALLOW FILTERING` demanded; 803 MB for six rows |
| **Neo4j** | a node and its relationships | one primary | a walk from a known node | sums over large sets; sharding | 182 hits for a two-step walk |
| **InfluxDB** | a point in a series | a shard per time range | a time range, aggregated | a tag with millions of values | three hours of minutes summed by hour; 30 days of retention |

Three things are true of all five, and they are the reason this course spent three lessons on
partitions, replicas and consistency before reaching them:

- **The key is the design.** Each one is fast exactly where its key lets it go straight to the
  data, and each refuses or overcharges everywhere else.
- **Each makes the trade of lesson 3 somewhere.** DynamoDB's reads are eventually consistent unless
  you pay for strong ones; Cassandra lets each query name its quorum; MongoDB lets each read and
  write choose; Neo4j keeps writes on a primary, and InfluxDB's open-source server is one node.
- **None of them is a reason to leave PostgreSQL on its own.** Each earned its place in this lesson
  by answering one question better, and lesson 4's section 10 is the test for whether that question
  is worth a second database in a system of yours.

## Cleaning up

Every container was removed at the end of its section. The images are still on disk; `docker image
ls` lists them with their sizes, and `docker image rm` followed by a name removes one. Lesson 6
returns to the box office and its PostgreSQL.
