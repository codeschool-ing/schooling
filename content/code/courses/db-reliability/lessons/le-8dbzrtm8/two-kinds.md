---
title: Copying bytes, or copying rows
version: 1
---

Everything since lesson 11 has been **physical replication**: the standby receives the write-ahead
log as the primary wrote it and replays it into a byte-for-byte copy of the primary's files. That has
three consequences that are its strength and its limit at once. The standby is a copy of **the whole
cluster**, every database and every table. It must run **the same major version** of PostgreSQL,
because the files and the log are in that version's format. And it is **read-only**, because a
single write of its own would make it a different set of files.

**Logical replication** decodes the same log into **row changes**, this row inserted into this table,
that one updated, and sends those. The receiving server applies them with ordinary inserts, updates and
deletes into tables of its own:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two rows. Physical: a PostgreSQL 16 primary sends the write-ahead log, as bytes, to a PostgreSQL 16 standby that holds a read-only copy of every file. Logical: a PostgreSQL 16 publisher decodes the log into row changes for the tables of a publication and sends them to a PostgreSQL 17 subscriber, which applies them to tables of its own and accepts writes.\"><defs><marker id=\"l14k-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--wire)\" font-weight=\"600\">physical</text><rect x=\"20\" y=\"46\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">primary</text><text x=\"120\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 16</text><text x=\"120\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">whole cluster</text><rect x=\"500\" y=\"46\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby</text><text x=\"600\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 16</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every file, read-only</text><path d=\"M222 81 L498 81\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14k-am)\"></path><text x=\"360\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the log, as bytes</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">logical</text><rect x=\"20\" y=\"166\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">publisher</text><text x=\"120\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 16</text><text x=\"120\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the tables of a publication</text><rect x=\"500\" y=\"166\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">subscriber</text><text x=\"600\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">PostgreSQL 17</text><text x=\"600\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own tables, writable</text><path d=\"M222 201 L498 201\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14k-am)\"></path><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">row changes</text></svg>", "caption": "The same write-ahead log, sent two ways. Physical replication copies bytes into a copy of the same version; logical replication decodes them into rows any version can apply."}
```

| | physical | logical |
|---|---|---|
| what is copied | the whole cluster, as files | the tables a publication names, as rows |
| versions | the same major version | any supported version to any other |
| the copy is | read-only, until promoted | an ordinary server that accepts writes |
| table definitions (DDL) | copied, like everything else | **not copied** |
| sequences | copied | **not copied** |
| what it is for | a standby to fail over to | upgrades, moving some tables, feeding another system |

The two rows in bold are the price, and this lesson pays both of them on purpose. The last row is the
reason to pay it: a logical copy can run **PostgreSQL 17** while the primary runs 16, which turns a
major-version upgrade from an outage of hours into a switch of minutes.

The vocabulary: a **publication** is the set of tables a server offers, a **subscription** is a
server's request to receive one, and the two servers are the **publisher** and the **subscriber**.
