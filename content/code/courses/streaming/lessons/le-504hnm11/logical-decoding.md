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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The path of one change from a table to a topic. A transaction commits and PostgreSQL writes it to the write-ahead log. The replication slot debezium_stock marks how far its reader has confirmed. The pgoutput plugin decodes the log from that point, keeping only the tables named in the publication ponto_final. Debezium, running inside Kafka Connect, turns each row change into an event and writes it to one topic per table: pf.public.books and pf.public.stock. The slot's position only moves when Debezium confirms, so everything after it stays on the database's disk.\" data-fig=\"l14-pipeline\"><defs><marker id=\"l14-pipeline-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"20\" width=\"400\" height=\"190\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">PostgreSQL</text><rect x=\"30\" y=\"55\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><path d=\"M 110 70 L 140 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><text x=\"260\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">write-ahead log (WAL)</text><rect x=\"145\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"193\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"217\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"241\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"265\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"313\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"361\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"241\" y1=\"54\" x2=\"241\" y2=\"108\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"241\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">slot debezium_stock</text><text x=\"195\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">confirmed up to here</text><text x=\"318\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">kept on disk until confirmed</text><rect x=\"150\" y=\"145\" width=\"230\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pgoutput</text><text x=\"265\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">publication ponto_final</text><path d=\"M 330 108 L 330 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><rect x=\"440\" y=\"110\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kafka Connect</text><text x=\"500\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Debezium connector</text><path d=\"M 380 169 L 438 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><rect x=\"590\" y=\"60\" width=\"115\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"647\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Kafka</text><rect x=\"598\" y=\"95\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">pf.public.books</text><rect x=\"598\" y=\"145\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">pf.public.stock</text><path d=\"M 560 135 L 596 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><path d=\"M 560 150 L 596 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path></svg>", "caption": "Logical decoding: the database's own log, read from a remembered position, filtered by a publication and turned into one topic per table."}
```

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
