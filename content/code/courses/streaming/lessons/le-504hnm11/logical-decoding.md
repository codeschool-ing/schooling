---
title: Logical decoding, the log under the table
version: 1
---

**PostgreSQL already keeps a log of every change, because it needs one to survive a crash.** Before
a transaction's `COMMIT` returns, its changes are written to the **write-ahead log** (WAL), a
sequence of files under the data directory; the tables themselves are brought up to date later. If
the server dies, it replays the WAL on the way back up. The WAL is ordered, append-only and
addressed by position, which makes it the same data structure as a Kafka partition from lesson 2.

What the WAL holds by default is not readable as rows. It records pages and bytes, enough for
PostgreSQL to repeat its own work and no more. **Logical decoding** is the feature that turns it
back into row changes — *this row of `stock` changed from 3 to 2* — and it needs four things,
each of which you will see by name in the rest of this lesson:

| piece | what it is | in this lesson |
|---|---|---|
| `wal_level = logical` | a server setting that makes the WAL carry enough to rebuild rows; changing it needs a restart | set while installing, in the next section |
| a **replication slot** | a named position in the WAL, kept by the server for one reader | `debezium_stock`, created by Debezium when it first connects |
| an **output plugin** | the code that turns WAL records into a format | `pgoutput`, PostgreSQL's own, the one its built-in replication uses |
| a **publication** | the list of tables whose changes `pgoutput` sends | `ponto_final`: the tables `books` and `stock` |

@@fig:l14-pipeline@@

## The slot is the consumer group of the database

**A slot is to PostgreSQL what a committed offset is to Kafka**: the reader's position, kept on the
server. When Debezium has written a batch of changes to Kafka safely, it tells the server *I have
everything up to here*, and the slot's `confirmed_flush_lsn` moves forward. An **LSN**, a log
sequence number such as `0/1A2B3C8`, is a byte position in the WAL, the database's word for an
offset.

The comparison breaks at one point, and it is the point that causes outages. Kafka deletes a
partition's old segments by its retention setting, whether or not anybody read them (lesson 3); a
consumer that falls too far behind loses data, and the broker's disk does not care. **PostgreSQL
does the opposite: it keeps every WAL file a slot has not confirmed**, for as long as it takes. A
reader that stops leaves the slot behind, and the database's disk fills with WAL nobody will read.
The last section of this lesson makes that happen on purpose and measures it.

## Why pgoutput and a publication

Older Debezium setups installed a separate plugin, `decoderbufs` or `wal2json`, into PostgreSQL.
`pgoutput` has been part of PostgreSQL since version 10, so there is nothing to compile, and the
managed services, Amazon RDS and Cloud SQL among them, support it. It sends only the tables in a
**publication**, which is an ordinary database object:

```sql
CREATE PUBLICATION ponto_final FOR TABLE books, stock;
```

Debezium can create the publication itself, for every table, on its first start. This lesson
creates it by hand instead, as the table owner, so that the connector's database user needs no
more than it has to: the right to replicate, and to read the two tables. **A CDC user that can
read every table in the database is a copy of all of it, on its way to a broker.** Naming the
tables in a publication is how you decide which ones leave.
