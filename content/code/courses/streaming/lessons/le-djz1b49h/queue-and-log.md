---
title: A queue and a log are different things
version: 1
---

**A queue holds work that has not been done yet; a log holds what happened.** The two look alike
from a distance — a producer writes messages, something else reads them — and the most common
mistake in this part of an architecture is to pick one when the problem is the other. Fourteen
lessons of this course have been about the log. This one is about the queue, and about telling
them apart.

@@fig:l15-queue-log@@

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
