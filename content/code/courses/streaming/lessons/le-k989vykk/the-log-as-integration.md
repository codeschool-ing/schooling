---
title: One write, many readers
version: 1
---

**A log lets one system write a fact once and lets any number of systems read it, each at its own
pace, without the writer knowing who they are.** Lesson 1 said this is often the main reason a
company adopts Kafka, even for data nobody needs in a hurry. This section says why it works, and
what it replaces.

## What it replaces

A sale at Ponto Final has to reach four places: the stock system, the loyalty scheme, the warehouse
and the accountant. Without a log, the till calls each of them. That looks like four lines of code
and is four ways to fail. If the loyalty scheme is down for maintenance, the till has to choose
between waiting, which stops the queue at the counter, and carrying on, which loses the customer's
points. If the till sends to stock and then crashes before the warehouse, two systems now disagree
about whether the sale happened, and nothing records which of them is right. Lesson 14 calls this
the **dual write** and shows it failing.

It also grows the wrong way. Five shops with a till each and four systems to tell is twenty
connections, each written and maintained by somebody. A fifth system is five more, and every till
has to be changed and redeployed to add it.

@@fig:l2-integration@@

With a log in the middle, the till writes each sale once and is finished. Each of the four systems
reads the log, at its own place, the way the stock and loyalty readers did with `minilog.py`. The
connections are now one per system, and a new system is a new reader that changes nothing on the
till.

## What the readers get

Three properties come with the structure, and none of them needs to be built:

- **Each reader goes at its own pace.** The accountant's job reads once a night; the stock system
  reads within a second. Neither slows the other down, because a reader's place is its own, and the
  log does not wait for the slowest. Lesson 16 is about watching a reader fall behind, which is
  called **lag**.
- **A reader can be added later and start from the beginning.** A recommendations system built next
  year can read every sale since the log began, if the log has kept them, the way the loyalty reader
  read from offset 0. How long a log keeps things is a setting, and lesson 3 sets it.
- **A reader can read again.** A loyalty scheme that miscounted points for a week fixes its code,
  moves its place back a week and reads again. This is called **replay**, and lesson 16 does it with
  Kafka's own tools.

The writer gives up something in exchange: it no longer knows whether anybody acted on the event.
A till that needs an answer, such as *was the card accepted?*, still sends a **command** to the
system that can answer, and waits. The log is for facts, and the till's job ends when the fact is
written.

## A queue is a different tool

A message **queue** also sits between writers and readers, and the two are often confused. A queue
hands each message to one of its readers, and once that reader confirms it, the message is deleted.
Several readers on one queue share the work rather than each seeing everything, and there is no
going back to read last week.

| | log | queue |
|---|---|---|
| a message read by one reader | is still there for every other reader | is gone once that reader confirms it |
| a new reader | can start from the beginning | sees only what arrives from now on |
| reading again | move the place back | not possible; the message was deleted |
| several readers | each reads everything, at its own place | share the messages between them |

Neither is better. A queue is the right tool when each message is a piece of work that should be
done once, by whoever is free: resizing an image, sending an email. Lesson 15 takes RabbitMQ and
Amazon SQS apart and says when a queue beats a log. Kafka can also share a topic's messages between
the copies of one program, which lesson 4 calls a **consumer group**, and that is how it does both
jobs at once.
