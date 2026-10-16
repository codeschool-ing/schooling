---
title: The dual write, and the moment between two writes
version: 1
---

**A program that writes a change to its database and then announces it on Kafka has two writes
and no transaction around them.** Ponto Final's website keeps its stock in PostgreSQL: a table
with one row per shop and book. When the website takes a reservation, it lowers the count in that
table. Every other system that cares about stock — the tills' screens, the warehouse, the
replenishment report — would like to hear about it, and the obvious way is for the same program to
send an event to a topic straight after the `UPDATE`.

That obvious way is called a **dual write**, and it fails in the gap between the two writes. Either
order has a version of it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two programs that write a sale to the database and to Kafka in two steps, and fail between them. Above, the database is written first: the stock is changed and committed, the program crashes, and the event is never sent, so every reader of the topic still believes the old stock. Below, Kafka is written first: the event is sent, then the database transaction fails and rolls back, so the readers hear of a sale that never happened.\" data-fig=\"l14-dual-write\"><defs><marker id=\"l14-dual-write-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">database first</text><line x1=\"130\" y1=\"70\" x2=\"540\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"138\" y=\"55\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UPDATE stock</text><rect x=\"258\" y=\"55\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"392\" y1=\"62\" x2=\"408\" y2=\"78\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"392\" y1=\"78\" x2=\"408\" y2=\"62\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"400\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">crash</text><rect x=\"433\" y=\"55\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"485\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">never sent</text><text x=\"640\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the table: 2 copies</text><text x=\"640\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the topic: still 3</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Kafka first</text><line x1=\"130\" y1=\"165\" x2=\"540\" y2=\"165\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"138\" y=\"150\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">send event</text><rect x=\"258\" y=\"150\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">UPDATE stock</text><line x1=\"392\" y1=\"157\" x2=\"408\" y2=\"173\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"392\" y1=\"173\" x2=\"408\" y2=\"157\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"400\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">crash</text><rect x=\"433\" y=\"150\" width=\"104\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"485\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rolled back</text><text x=\"640\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the topic: 2 copies</text><text x=\"640\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the table: still 3</text><path d=\"M 130 225 L 540 225\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-dual-write-ah-8343)\"></path><text x=\"335\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Two writes, and the crash between them. Whichever goes first, one side ends up saying something the other does not."}
```

- **Database first.** The `UPDATE` commits, and the program dies before `produce` is called — a
  deploy, an out-of-memory kill, a broker that does not answer within the timeout. The table says
  two copies; the topic, and everything that reads it, still says three. Nothing retries, because
  nothing remembers that a send was owed.
- **Kafka first.** The event goes out, and then the `UPDATE` fails: a constraint, a deadlock, a
  transaction rolled back by somebody else's lock. The topic announced a reservation the database
  never made, and a reader has already acted on it.

The common wrong answer is to put the send *inside* the database transaction, before the
`COMMIT`. It narrows the gap and does not close it, because Kafka cannot take part in
PostgreSQL's transaction: the send can succeed and the commit fail, which is the second case
again. Lesson 7's Kafka transactions do not help either. **They make writes to several topics
atomic with one another, and a database is not a topic.**

## Two ways out

The gap closes only when there is **one write**, and something derives the second from it. There
are two places that write can go.

| | the one write | what derives the event |
|---|---|---|
| **the outbox** (lesson 8) | the change *and* an event row, in one database transaction | a relay that reads the outbox table and sends its rows |
| **change data capture** | the change, and nothing else | a reader of the database's own log of changes |

This lesson is about the second. **Change data capture (CDC) treats the database as the producer.**
Every committed `INSERT`, `UPDATE` and `DELETE` already goes into PostgreSQL's write-ahead log
before the commit returns. A program that reads that log sees every change, in commit order,
including the ones made by a script somebody ran at midnight and by programs that have never
heard of Kafka.

If you took `pipelines-etl`, you have already done this by hand: its lesson 5 opens a replication
slot with `test_decoding`, reads the changes as text with SQL and applies them to a warehouse
table. Here the reader is **Debezium**, a set of Kafka Connect connectors that do the same
reading, keep their position safely, and write each change to a topic as a structured event.

One limit comes first. **The events are row
changes, not business facts.** `stock` lost one copy of `bk-02` in Recife; the event does not say
it was a reservation, by whom or from which screen, because the table never knew. An outbox row
can carry that, which is why the two techniques live side by side rather than one replacing the
other.
