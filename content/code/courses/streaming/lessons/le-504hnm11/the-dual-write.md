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

@@fig:l14-dual-write@@

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

This lesson is about the second. **Change data capture (CDC) treats the database as the producer**:
every committed `INSERT`, `UPDATE` and `DELETE` already goes into PostgreSQL's write-ahead log
before the commit returns, so a program that reads that log sees every change, in commit order,
including the ones made by a script somebody ran at midnight and by programs that have never
heard of Kafka.

If you took `pipelines-etl`, you have already done this by hand: its lesson 5 opens a replication
slot with `test_decoding`, reads the changes as text with SQL and applies them to a warehouse
table. Here the reader is **Debezium**, a set of Kafka Connect connectors that do the same
reading, keep their position safely, and write each change to a topic as a structured event.

What CDC does not give you is worth saying before it gives you anything. **The events are row
changes, not business facts.** `stock` lost one copy of `bk-02` in Recife; the event does not say
it was a reservation, by whom or from which screen, because the table never knew. An outbox row
can carry that, which is why the two techniques live side by side rather than one replacing the
other.
