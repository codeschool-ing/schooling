---
title: Choosing between a queue and a log
version: 1
---

**Ask what a message is for once it has been handled.** If the answer is *nothing — the job is
done*, it is work, and a queue fits. If the answer is *somebody else may want it, now or later*,
it is an event, and a log fits. Most of the other questions follow from that one.

| what you need | lean towards | because |
|---|---|---|
| each message handled once, by any free worker | a queue | competing consumers and per-message acknowledgement are what it is |
| several systems reading the same events | a log | one write, many independent readers, no copy per reader |
| replay: a new reader, a fixed bug, a rebuilt table | a log | the queue deleted the messages it delivered |
| order per customer, shop or account | a log with a key (lesson 3), or an SQS FIFO queue with a group id | a plain queue redelivers out of order |
| a slow job per message: a PDF, an e-mail, a label | a queue | one stuck message blocks one worker, not a partition |
| retry one message later, set aside a bad one | a queue | dead-lettering and per-message TTL are built in |
| hundreds of thousands of messages a second, kept for days | a log | sequential writes to segment files, sized in lesson 17 |
| no servers to run at all | SQS and SNS | the provider runs them and charges per request |

**The slow-job row is the one people miss.** A Kafka consumer commits an offset, a position, so
partition order is the unit of progress: a message that takes ten minutes holds up everything behind
it in that partition (lesson 16 calls it a poison message when it never finishes). A queue
acknowledges messages one by one, so the order a packer finishes in does not matter, and the next
order goes to whoever is free.

## They are combined more often than chosen

Ponto Final ends up with both, which is the usual outcome. The tills write sales to Kafka, because
the stock, the loyalty points and the warehouse all read them, and the warehouse load replays a
day when it has to. Online orders that must be packed go on a RabbitMQ queue, because each one is
a task for one packer and the queue's length is the backlog. Between the two sits a small consumer
that reads the `sales` topic and puts one message on the `packing` queue for each sale that needs
shipping — **the log for what happened, the queue for what has to be done about it**.

The lines are also less sharp than the table makes them. RabbitMQ has had **streams** since 3.9, a
log-like queue type that keeps messages after they are read and lets consumers start from an
offset. Kafka 4 adds **share groups** (KIP-932), where members of one group take records one at a
time and acknowledge each, the way queue consumers do. Neither was run for this course, and neither
changes the question at the top of this section: they let one product answer both ways, not
answer it for you.

## What it costs to run

A queue keeps little: messages leave as they are acknowledged, so its disk is the backlog and
nothing more. A log keeps everything for its retention, three times over with replication, which is
lesson 17's arithmetic. Against that, a queue that grows because its consumers stopped grows on one
node's memory and disk, and when either passes its alarm threshold RabbitMQ blocks the publishers,
by design, until the backlog drains. SQS and SNS move the running to Amazon
and the cost to a bill per request, which for a steady stream of small messages is the line to
check before choosing them.
