---
title: Ordering, the promise most often assumed
version: 1
---

Quitanda's orders produce three events in sequence: `OrderCreated`, `OrderPaid`, `OrderShipped`. A
consumer that keeps the order's status applies them in the order it receives them. **If it receives
them out of order, the status ends wrong and nothing reports an error**: an order applied as created,
shipped, then paid ends the day as "paid", a step behind reality, and the customer is told the parcel
has not left.

## Where order is lost

A broker keeps order only along one path from one producer to one consumer. Each of these breaks it:

| cause | what happens |
| --- | --- |
| competing consumers on one queue | lesson 6 showed order 10 finishing before order 9: each consumer works at its own speed |
| a redelivery | a message returned after a crash comes back behind messages published after it |
| retries in the producer | a publish that is retried can land after the next one, unless the client prevents it |
| several partitions | Kafka keeps order within a partition and none across them |
| several producers | two services publishing about one order have no shared clock |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three events for one order, created, paid and shipped, in one queue. Two competing consumers take them: consumer 1 takes created and shipped, consumer 2 takes paid but is slower, so shipped is applied before paid. Below, the fix: with the order id as the key, all three go to one partition and one consumer, in order.\"><defs><marker id=\"l7-order-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">one queue, two competing consumers</text><rect x=\"40\" y=\"48\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">created</text><rect x=\"130\" y=\"48\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">paid</text><rect x=\"220\" y=\"48\" width=\"80\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shipped</text><rect x=\"360\" y=\"44\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer 1: 1, 3</text><rect x=\"530\" y=\"44\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer 2: 2, slow</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">applied: created, shipped, paid</text><text x=\"26\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">keyed by order id</text><rect x=\"40\" y=\"168\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 2: created, paid, shipped</text><rect x=\"430\" y=\"168\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one consumer, in order</text><path d=\"M332 190 L428 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-order-ah-phosphor)\"></path></svg>", "caption": "Competing consumers reorder the events of one order. Keying by the order id sends all of one order's events to one consumer, in the order they were written."}
```

## Keeping the order that matters

**Order is almost never needed globally, only per entity**: the events of one order, the movements of
one product's stock. That narrower promise is cheap to keep:

- **Key by the entity.** In Kafka, the order id as the message key sends all of one order's events to
  one partition, read by one consumer of the group, in the order they were written. The parallelism
  comes from different orders landing in different partitions. SQS FIFO's message group and Service
  Bus's sessions are the same idea.
- **One consumer per stream of events that must stay in order.** RabbitMQ's *single active consumer*
  option on a queue lets several consumers connect and only one receive at a time, with the others as
  standbys.
- **Make the consumer able to tell.** Each event carries a version or sequence number for its entity,
  and the consumer applies an event only if it is the next one, holding or discarding older ones. That
  works even where the transport cannot keep order, and it combines naturally with idempotency: a
  version already applied is a duplicate.

## And what to do instead

Many consumers do not need order at all if each event carries the full state rather than a change.
"Order 41 is now shipped, with these items, at this time" can be applied in any order if the consumer
keeps the event with the latest timestamp or version and ignores older ones. **Designing events so that
order does not matter is usually cheaper than guaranteeing it**, and lesson 9 returns to the idea as
last-writer-wins.
