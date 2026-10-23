---
title: At most once, at least once, and "exactly once"
version: 1
---

Every broker's documentation promises delivery, and many promise "exactly once". The promise is
true about something narrower than it sounds. **What decides whether a message is lost, delivered
once or delivered twice is the moment the consumer says "done" relative to the moment it does the
work**, and that moment is in your code, not in the broker.

## The acknowledgement

A broker hands a message to a consumer and waits to hear that it has been dealt with. Until it
hears, it keeps the message. When it hears, it forgets it: deletes it from the queue, or, in a log,
records the consumer's new offset. That signal has different names in different products. JMS and
RabbitMQ call it an acknowledgement, IBM MQ a commit of the unit of work in which the message was
read, Amazon SQS a deletion, Kafka a commit of the offset. The idea is the same, and so is the
problem: **the work and the acknowledgement happen in two different systems, one after the other,
and a consumer can stop between them.**

There are two orders to put them in, and each fails in its own direction.

**Acknowledge first, then work.** The broker forgets the message the moment the consumer receives
it. If the consumer dies before finishing, nobody has the message any more. It was delivered at
most once, and in this case zero times. This is **at-most-once**, and it is the right choice only
for messages whose loss nobody would notice: a reading from a tank thermometer that sends another
one a minute later, a page view for a dashboard.

**Work first, then acknowledge.** The broker keeps the message until the work is done. If the
consumer dies before acknowledging, the broker gives the message to somebody else, or to the same
consumer when it restarts. Nothing is lost. But if the consumer died *after* finishing the work and
before the acknowledgement left, the work is done twice. This is **at-least-once**, and it is what
every message about money, stock or a farm's milk must have.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l10-redelivery\" aria-label=\"A sequence diagram read from top to bottom, with three lifelines: the broker, the consumer and the ledger database. The broker delivers m-2; the consumer inserts the payment and the ledger commits it. The consumer then crashes before acknowledging. The broker, which never heard an acknowledgement, still holds m-2 and delivers it again after a timeout. The consumer inserts the payment a second time and the ledger commits it, so the payment is recorded twice. Only then does the acknowledgement reach the broker.\"><defs><marker id=\"l10-redelivery-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-redelivery-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l10-redelivery-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"54.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broker</text><path d=\"M110.0 40.0 L110.0 312.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"304.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">consumer</text><path d=\"M360.0 40.0 L360.0 312.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"554.0\" y=\"12.0\" width=\"112.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ledger</text><path d=\"M610.0 40.0 L610.0 312.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M114.0 70.0 L354.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-phosphor)\"></path><text x=\"235.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deliver m-2</text><path d=\"M364.0 98.0 L604.0 98.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-phosphor)\"></path><text x=\"485.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">insert payment</text><path d=\"M606.0 126.0 L366.0 126.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-redelivery-es-ah-paper-dim)\"></path><text x=\"485.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">committed</text><path d=\"M353.0 145.0 L367.0 159.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M353.0 159.0 L367.0 145.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"376.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">crash: no acknowledgement</text><text x=\"104.0\" y=\"183.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">timeout: m-2</text><text x=\"104.0\" y=\"196.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">still held</text><path d=\"M114.0 218.0 L354.0 218.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-phosphor)\"></path><text x=\"235.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deliver m-2 again</text><path d=\"M364.0 246.0 L604.0 246.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l10-redelivery-es-ah-amber)\"></path><text x=\"485.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">insert payment again</text><path d=\"M606.0 274.0 L366.0 274.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-redelivery-es-ah-paper-dim)\"></path><text x=\"485.0\" y=\"265.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">committed: recorded twice</text><path d=\"M356.0 302.0 L116.0 302.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l10-redelivery-es-ah-paper-dim)\"></path><text x=\"235.0\" y=\"293.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acknowledge</text></svg>", "caption": "Acknowledging after the work loses nothing. A crash between the work and the acknowledgement means the work is done twice, unless the consumer can tell."}
```

At-least-once is not a defect to be configured away. It is the price of not losing anything, and a
consumer that does not know it is paying it will do the work twice without noticing.

## Duplicates without a crash

A crash is the dramatic case and not the common one. Three ordinary situations redeliver a message
whose work was done:

- **A consumer that is slow.** Amazon SQS hides a received message for a visibility timeout, 30
  seconds unless configured otherwise, and shows it again if the consumer has not deleted it by
  then. A consumer that takes 40 seconds over one message, because the system behind it is slow,
  finishes the work and then finds that another instance has started it again.
- **A connection that drops.** The consumer acknowledges, the network loses the acknowledgement,
  and the broker never learns. To the broker this looks exactly like a crash.
- **A producer that is not sure.** A publish that times out leaves the producer not knowing whether
  the broker received it. Sending again is the only safe choice, and if the first attempt did
  arrive, the queue now holds two copies. The duplicate is born before any consumer sees it.

Serra Alta learned the size of this in an evening. During the month-end close of March 2025 the
queue manager under the bus was restarted while the flow that copies SAP invoices into Salesforce
was busy. 212 invoices had been written to Salesforce and not yet acknowledged. All 212 were
delivered again after the restart, and Salesforce created 212 duplicate invoice records. For two
days the key-account reps saw customers owing twice what they owed, and Talita Gomes spent most of
a week finding and deleting the copies by hand.

**A duplicate rate is small and never zero.** About 1,400 orders, a similar number of deliveries and as many
invoices cross the bus on a weekday, so the order and invoice flows alone move about ninety
thousand messages a month; a rate of one in a thousand is ninety duplicates. Design for them, because they will arrive.

## What "exactly once" means when a product says it

When a product claims exactly-once, read what it is exactly-once *about*. Three real claims, each
true and each narrower than the phrase:

| claim | what it actually covers | what it does not |
|---|---|---|
| IBM MQ's assured, once-only delivery | a persistent message moving between queue managers arrives once; a get inside a unit of work is backed out and returned to the queue if the program fails before committing | what the program did with the message before it failed |
| Kafka's exactly-once semantics | a program that reads from Kafka and writes to Kafka can commit its output and its offsets in one Kafka transaction; the idempotent producer removes duplicates caused by its own retries | a write to anything that is not Kafka, such as a database or an email |
| Amazon SQS FIFO queues | a message sent twice with the same deduplication id within a five-minute interval is accepted once | a consumer that receives the message and fails to delete it in time |

All three are serious engineering and worth having. None of them can make your database update and
the broker's acknowledgement into one event, because the broker does not own your database.

There is one classic way to do exactly that: a **distributed transaction** in which the database
and the queue manager both take part and commit together, by the two-phase commit of the XA
standard. IBM MQ can coordinate one with a database such as Db2 or Oracle, and some of Serra Alta's
older flows use it. It works, at a price: every message pays for two phases of agreement, a
participant that stops at the wrong moment leaves work locked until somebody resolves it, and most
cloud brokers and Kafka do not take part at all. It is a tool for a few flows, not a design for all
of them.

## Exactly once, end to end

**What a business means by "exactly once" is "the effect happens once", and the reliable way to
get it is at-least-once delivery plus a consumer that recognises a message it has already
handled.** Sometimes called *effectively once*, it moves the guarantee from the transport, which
cannot give it, to the consumer, which can.

That splits the work in two clear halves:

1. The transport makes sure nothing is lost: persistent messages, acknowledgement after the work,
   retries on the producer side.
2. The consumer makes sure a repeat changes nothing. The next section builds one, in a short Python
   program, and redelivers a message to it.

Joana's rule for every new consumer at Serra Alta is the two halves in one sentence: **acknowledge
after the work, and make the work safe to repeat.** The first half is configuration. The second half
is design, and it is the half nobody does by accident.
