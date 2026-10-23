---
title: Queues, topics and logs
version: 1
---

A message channel answers one question before any other: **when a message arrives, who gets it?** A
queue gives each message to exactly one consumer. A topic gives every subscriber a copy of its own.
A log keeps every message and lets each reader keep its own place in it. Almost everything else a
broker does, from retries to ordering, is a consequence of which of the three you are using.

The common mistake is to treat the three as one thing with three product names, so that "we have
Kafka" or "we have MQ" seems to settle the design. It settles very little. IBM MQ offers queues and
topics, Kafka can be made to behave like a queue, and a cloud provider sells both shapes as separate
services. The shape is a decision about the business, and the product is a decision about who will
run it.

## Point to point: one message, one consumer

Under Rui Andrade's bus there is a queue manager, and most of the 70 flows from lesson 8 start by
reading a queue. One of them is `SA.PORTAL.ORDERS`, where the Portal B2B puts each order a bakery
places and from which an ESB flow creates the sales order in SAP. **An order must become one sales
order, so it must be taken by one reader**: that is the promise of a queue, which Hohpe and Woolf
(2003) call a point-to-point channel.

The queue also does the job lesson 9 gave messaging in general. Every Sunday from 01:00 to 05:00
SAP is down for maintenance (lesson 1), and the portal goes on taking orders. They wait in the
queue, and the flow drains it when SAP comes back. The portal does not need SAP to be up at the
moment it publishes; it needs the queue manager to be up, which is a much smaller thing to keep
running.

When one reader is too slow, you start more. Several instances of the same flow read the same
queue, and the queue manager hands each message to one of them. This is the **competing consumers**
arrangement, and it is how a queue scales: the work is shared, and nobody gets the same order
twice in normal running. The arithmetic is plain. At Serra Alta the order flow spends about 250 ms
on each message, mostly waiting for SAP, so one instance handles 4 orders a second. In the first
five working days of the month, when finance is closing and customers are restocking at the same
time, Rui runs four instances, which take 16 a second between them.

Competing consumers have a cost that this lesson returns to in its last section: once two readers
share a queue, the order in which messages are finished is no longer the order in which they were
put.

## Publish and subscribe: one message, a copy each

Now take a different message. When a bakery pays an invoice through the portal, three systems care.
Finance's ledger records the payment. Salesforce shows the key-account rep that the customer is up
to date. The credit approval process in IBM BPM may release a customer it had blocked. **Each of
them needs the whole message, and none of them should take it away from the others.**

That is a topic, the publish-subscribe channel. The portal publishes `invoice.paid` once, to the
topic, and the broker delivers a copy to each subscription. The portal does not know the three
exist, which is the point lesson 9 made about events: adding a fourth interested system is a new
subscription, not a change to the portal.

Two details decide whether a topic is safe to depend on:

- A **durable** subscription keeps the copies for a subscriber that is down and hands them over
  when it comes back. A non-durable one delivers only to whoever is connected at the moment of
  publishing, so ten minutes' restart of the flow that feeds Salesforce would quietly cost it every
  payment made in those ten minutes. In JMS the two are separate calls, and the difference is one word in the code.
- **In most brokers a subscription is a queue.** IBM MQ delivers a subscription's copies to a queue,
  RabbitMQ binds one queue per subscriber to an exchange, and Azure Service Bus gives each
  subscription of a topic its own queue-like store. So the two shapes combine: the topic makes the
  copies, and each subscriber reads its copy through competing consumers if it needs more than one
  instance.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l10-shapes\" aria-label=\"Three panels side by side. Queue: a producer puts m1, m2 and m3 on one queue; consumer A receives m1 and m3 and consumer B receives m2, so each message goes to one consumer. Topic: a publisher sends m1 to m3 to a topic, which copies all three into two subscriptions, each read by its own consumer, so every subscription gets a copy. Log: a producer appends to a log of six numbered positions, 0 to 5; reader A is at offset 3 and reader B at offset 5, and reading removes nothing.\"><defs><marker id=\"l10-shapes-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l10-shapes-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"115.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">queue</text><rect x=\"60.0\" y=\"38.0\" width=\"110.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">producer</text><rect x=\"50.0\" y=\"104.0\" width=\"130.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"60.0\" y=\"110.0\" width=\"34.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"77.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><rect x=\"98.0\" y=\"110.0\" width=\"34.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><rect x=\"136.0\" y=\"110.0\" width=\"34.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"153.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><path d=\"M115.0 66.0 L115.0 102.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-paper-dim)\"></path><rect x=\"14.0\" y=\"200.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer A</text><rect x=\"124.0\" y=\"200.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer B</text><path d=\"M95.0 138.0 L65.0 198.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><path d=\"M135.0 138.0 L165.0 198.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"52.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1, m3</text><text x=\"172.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><text x=\"115.0\" y=\"269.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">each message goes</text><text x=\"115.0\" y=\"282.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">to one consumer</text><path d=\"M238.0 30.0 L238.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">topic</text><rect x=\"305.0\" y=\"38.0\" width=\"110.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">publisher</text><rect x=\"305.0\" y=\"91.0\" width=\"110.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">topic</text><path d=\"M360.0 66.0 L360.0 89.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-paper-dim)\"></path><rect x=\"252.0\" y=\"150.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"257.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"271.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><rect x=\"290.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><rect x=\"323.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"337.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><text x=\"304.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subscription 1</text><rect x=\"258.0\" y=\"216.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer</text><path d=\"M304.0 200.0 L304.0 214.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><rect x=\"364.0\" y=\"150.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"369.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"383.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><rect x=\"402.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><rect x=\"435.0\" y=\"154.0\" width=\"28.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"449.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><text x=\"416.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subscription 2</text><rect x=\"370.0\" y=\"216.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumer</text><path d=\"M416.0 200.0 L416.0 214.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><path d=\"M342.0 117.0 L312.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><path d=\"M378.0 117.0 L408.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"269.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">every subscription</text><text x=\"360.0\" y=\"282.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">gets a copy</text><path d=\"M482.0 30.0 L482.0 310.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"603.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">log</text><rect x=\"548.0\" y=\"38.0\" width=\"110.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"603.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">producer</text><rect x=\"489.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m0</text><text x=\"506.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"524.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m1</text><text x=\"541.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"559.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"576.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m2</text><text x=\"576.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"594.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"611.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m3</text><text x=\"611.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"629.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"646.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m4</text><text x=\"646.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"664.5\" y=\"110.0\" width=\"33.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"681.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">m5</text><text x=\"681.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><path d=\"M603.0 66.0 L603.0 80.0 L681.0 80.0 L681.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-paper-dim)\"></path><text x=\"644.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">append</text><rect x=\"578.0\" y=\"200.0\" width=\"66.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"611.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reader A</text><path d=\"M611.0 200.0 L611.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"611.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">offset 3</text><rect x=\"648.0\" y=\"200.0\" width=\"66.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"681.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reader B</text><path d=\"M681.0 200.0 L681.0 158.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-es-ah-phosphor)\"></path><text x=\"681.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">offset 5</text><text x=\"603.0\" y=\"275.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">reading removes nothing;</text><text x=\"603.0\" y=\"288.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">each reader keeps its offset</text></svg>", "caption": "The same three messages under three models. A queue shares them out, a topic copies them, and a log keeps them and lets each reader remember where it stopped."}
```

## The log: nothing is taken away

Apache Kafka, written at LinkedIn and open-sourced in 2011, works differently from both. A Kafka
topic is a **log**: messages are appended to it and stay there, in order, until a retention limit
of time or size removes the oldest. Reading a message does not delete it. Each reader keeps an
**offset**, its own position in the log, and moves it forward as it goes.

Several consequences follow from that one difference:

- A new subscriber can start at the beginning and read the history, as far back as retention
  keeps it. With a queue, a system added in October has never seen September.
- A reader that processed something wrongly can move its offset back and read again. With a queue,
  a message that has been taken is gone.
- Kafka splits each topic into **partitions**, and within a consumer group each partition is read
  by one member at a time. The group shares the work like competing consumers, but the number of
  partitions caps it: twelve partitions keep at most twelve members busy.

What a log does not give you is the bookkeeping a queue does for you. A queue knows which message
each consumer has and puts it back if the consumer dies. A log knows only the offset the consumer
last committed, so the consumer decides when to commit, and that decision is the subject of the
next section.

## The products, by family

| family | examples | the model | at Serra Alta |
|---|---|---|---|
| message queue manager | IBM MQ, sold as MQSeries from 1993 and later as WebSphere MQ | queues, with topics on top; persistent messages, transactions | under the ESB since 2015 |
| AMQP broker | RabbitMQ, Apache ActiveMQ | exchanges or addresses routing to queues | none |
| log | Apache Kafka, and services compatible with its protocol | partitioned, retained, replayable | none |
| cloud service | Amazon SQS and SNS, Azure Service Bus, Google Cloud Pub/Sub | queues and topics as a managed service, paid per use | none yet |

The table is about models, not quality. IBM MQ has been moving bank payments for three decades.
Its strengths are the ones a dairy paying 1,900 farms on the 10th of the month wants: a message
written as persistent survives a restart, and a put or a get can take part in a transaction.

## Two standards, and what each one standardises

Two names turn up in every comparison of brokers, and they standardise different things.

**JMS, the Java Message Service, is an API.** It defines the interfaces a Java program uses to send
and receive: queues, topics, durable subscriptions, sessions and acknowledgement modes. It is now
maintained as Jakarta Messaging. A program written against JMS can move from one provider to
another with changes in configuration rather than code, but **two JMS providers cannot talk to each
other**, because JMS says nothing about the bytes on the wire. An IBM MQ client cannot connect to
ActiveMQ because both are "JMS".

**AMQP 1.0 is a wire protocol.** It was approved as an OASIS standard in 2012 and as ISO/IEC 19464
in 2014, and it fixes the bytes, so a client from one vendor can talk to a broker from another.
Azure Service Bus uses it as its main protocol, and ActiveMQ supports it. A trap hides in the name:
RabbitMQ was built on AMQP 0-9-1, an earlier protocol that is a different design and not
compatible with 1.0, although RabbitMQ now speaks both.

## What Joana chose

Joana arrived from a fintech where every service published to Kafka, and her first sketch for the
portal's `invoice.paid` event had a Kafka cluster in it. Rui asked who would be woken at three in
the morning when it misbehaved. His team of four already ran IBM MQ, with monitoring, backups and a
support contract, and MQ has topics with durable subscriptions. Nothing in the portal's events
needed replay from a log.

**The new events go to topics on the queue manager Serra Alta already runs.** Joana wrote it as an
ADR with one condition that would reopen it: a consumer that needs to read history it was not
subscribed to when it happened. Choosing the shape took a paragraph. Choosing the product was a
question about the people who would operate it.
