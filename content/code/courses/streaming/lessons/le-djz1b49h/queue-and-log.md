---
title: A queue and a log are different things
version: 1
---

**A queue holds work that has not been done yet; a log holds what happened.** The two look alike
from a distance — a producer writes messages, something else reads them — and the most common
mistake in this part of an architecture is to pick one when the problem is the other. Fourteen
lessons of this course have been about the log. This one is about the queue, and about telling
them apart.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The same six messages in a queue and in a log. Above, a queue: two workers take turns, each message goes to one of them, and a message is deleted the moment its worker acknowledges it, so only the two not yet handled remain. Below, a log: all six stay where they were written, and two readers each keep their own position, one at offset 2 and one at offset 5, and either can go back to offset 0.\" data-fig=\"l15-queue-log\"><defs><marker id=\"l15-queue-log-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">queue</text><rect x=\"110\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"129\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"156\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"175\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"202\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"221\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"248\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"267\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"294\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"313\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"340\" y=\"55\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"198\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">acknowledged, deleted</text><text x=\"336\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">waiting</text><rect x=\"540\" y=\"30\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker A</text><rect x=\"540\" y=\"84\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">worker B</text><path d=\"M 386 64 L 536 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-queue-log-ah-8343)\"></path><path d=\"M 386 76 L 536 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-queue-log-ah-8343)\"></path><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">log</text><rect x=\"110\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"129\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"156\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"202\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"221\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"248\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"267\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"294\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"313\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"340\" y=\"175\" width=\"38\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><line x1=\"221\" y1=\"168\" x2=\"221\" y2=\"148\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"221\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">reader: stock</text><line x1=\"359\" y1=\"168\" x2=\"359\" y2=\"148\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"359\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">reader: warehouse</text><path d=\"M 350 210 Q 300 252 129 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15-queue-log-ah-8343)\"></path><text x=\"300\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replay from 0</text></svg>", "caption": "A queue hands each message to one worker and forgets it once acknowledged; a log keeps every message and lets each reader keep its own place."}
```

## What a queue does

Ponto Final's website takes online orders, and each order has to be packed by somebody in the
warehouse in Recife. That is **work**: each order must be packed once, by one packer, and once it
is packed nobody needs the message again. A queue is built for exactly that:

- **One message goes to one consumer.** Three packers reading the same queue are **competing
  consumers**: the broker hands each order to whichever packer is free, and no two get the same
  one. Adding a fourth packer adds capacity, immediately, with no partitions to plan.
- **An acknowledgement deletes it.** When the packer says *done*, the broker removes the message.
  The queue's length is the work outstanding, which is the number a warehouse manager wants on a
  screen.
- **No acknowledgement means somebody else gets it.** A packer that dies holding an order does not
  lose it; the broker gives it to another one. That is at-least-once delivery, the same guarantee
  lesson 7 built with offsets, here built into the broker.

## What a queue does not do

Everything a log is good at, a queue gives up by deleting:

| question | a log (Kafka) | a queue (RabbitMQ, SQS) |
|---|---|---|
| who reads a message | every group that subscribes, each at its own pace | one consumer, then it is gone |
| can I read it again tomorrow | yes, until retention removes it | no; it was deleted on acknowledgement |
| a new system wants last month's events | point it at offset 0 | they are not anywhere |
| in what order | per partition, kept on disk | roughly arrival order; a redelivered message comes back later |
| how to add readers | more partitions, planned (lesson 3) | start another consumer |

**A queue has no replay.** That one row is what decides most cases. Lesson 2 called the log an
integration point, because one write is read by the stock, the loyalty points and the warehouse,
each on its own schedule, and a fourth reader can arrive next year and start from the beginning.
Put the same sales in a queue and the first reader to take a sale removes it from the other three.

The usual repair, a separate queue for each reader with the broker copying every message into each,
is real and the next sections build it. **It gives each reader its own copy of the future, not of
the past**: a queue created today starts empty, whatever was published yesterday.

## Neither is a database

Both are tempting places to keep state, and neither should be. A queue deletes what it delivers, so
a message that *is* the record — a payment, a reservation — has to be written somewhere durable by
whoever processes it. A log keeps messages longer, but only as long as retention or compaction says,
which is lesson 3's subject. The answer to *what is the stock now* lives in a table, as lesson 14's
`stock` did; queues and logs are how changes travel between the places that keep it.
