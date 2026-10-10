---
title: What you would buy instead
version: 1
---

Almost nobody shards by hand any more, the way the lab did. The options sit on a line from "the
database you know, with copies" to "a database built to be split":

| what | replication | sharding | what changes for the application |
| --- | --- | --- | --- |
| managed PostgreSQL or MySQL (Amazon RDS, Cloud SQL, Azure Database) | read replicas and a standby, configured with a few settings | none | nothing; reads from replicas are eventually consistent |
| Amazon Aurora, AlloyDB | storage copied across zones by the provider | none for writes | nothing; one writer, with very fast failover |
| Citus (PostgreSQL extension), Vitess (MySQL) | each shard is a replicated database | by a key you choose per table | queries that include the key are fast; the rest work, and cost more |
| CockroachDB, Google Spanner, YugabyteDB, TiDB | each range of keys is replicated with Raft | automatic, by ranges that split and move | SQL as before; transactions across ranges are slower and can be retried |
| MongoDB, Cassandra, DynamoDB | built in | by a partition key you choose per collection or table | the key decides which queries are cheap, from the first day |

The databases in the fourth row are often called **distributed SQL**. They keep transactions and SQL
across shards by running consensus for every range of keys, which is the majority rule of this lesson
applied thousands of times, and they pay for it in latency: a write waits for a majority, often across
zones.

## Where Quitanda stands

One PostgreSQL server, with a standby for failures and, when the catalogue pages need it, a read replica.
That is the first row of the table, and it will carry Quitanda for a long time. **Sharding is a
response to a measurement**: the biggest machine is full, or the
writes no longer fit, and the copies cannot help because every copy holds everything. Until a number says
so, the cost of the second half of this lesson is all cost.

Stop the shards before leaving:

```sh
docker compose down -v
```
