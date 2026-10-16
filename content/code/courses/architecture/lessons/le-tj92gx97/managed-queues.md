---
title: Managed queues and logs
version: 1
---

Running a broker well is a job: clusters of three or more nodes, disks that must not fill, upgrades
without downtime, monitoring of queue depth and lag. **Every cloud provider sells a broker that is their
job instead of yours**, and they come in the same two families as before.

| family | managed products | what you give up |
| --- | --- | --- |
| queue, provider's own design | Amazon SQS, Google Cloud Pub/Sub, Azure Service Bus | the broker's own features beyond what the service offers, and portability between providers |
| queue, RabbitMQ underneath | Amazon MQ, CloudAMQP | little in the model; you still choose instance sizes |
| log, Kafka underneath | Amazon MSK, Confluent Cloud, Aiven | some configuration control; Kafka's model stays as it is |
| log, provider's own design | Amazon Kinesis Data Streams, Azure Event Hubs | the Kafka tools, though Event Hubs also speaks Kafka's protocol |

## Acknowledging by deleting

The provider-designed queues share one idea worth seeing once, because it shapes how a consumer is
written. Amazon SQS calls it the **visibility timeout**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline for one message in a managed queue. Consumer A receives it, and the message becomes invisible to other consumers for the visibility timeout, 30 seconds. Consumer A crashes without deleting it. When the timeout expires the message becomes visible again and consumer B receives it and deletes it.\"><defs><marker id=\"l6-visibility-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M60 200 L690 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6-visibility-ah-wire)\"></path><text x=\"375\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><rect x=\"80\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">A receives</text><rect x=\"200\" y=\"100\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">invisible for 30 s</text><rect x=\"250\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">A crashes</text><rect x=\"520\" y=\"40\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">B receives, deletes</text><path d=\"M200 160 L200 198\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M500 160 L500 198\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"350\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nobody else sees it</text></svg>", "caption": "A managed queue's acknowledgement is a deletion before a deadline. A consumer that dies without deleting gives the message back when the deadline passes."}
```

A consumer that receives a message does not hold it on a connection, as a RabbitMQ consumer does. The
message becomes **invisible** to other consumers for a set time, 30 seconds by default in SQS, and the
consumer acknowledges it by **deleting** it before that time is up. If the consumer crashes, or simply
takes longer than the timeout, the message becomes visible again and another consumer receives it.

Two consequences follow, and both lead to lesson 7. A consumer that takes longer than the timeout
**processes the message twice**, once in each consumer, so the timeout has to be longer than the slowest
normal handling, and the handling has to be safe to repeat. And a message that fails every time would
come back for ever, so the queue is given a **dead-letter queue**: after a set number of receives, the
message is moved there for a person to look at.

## What to check before choosing one

- **Ordering**: SQS standard queues make no promise of order; SQS FIFO queues keep order within a
  *message group*, which plays the part of Kafka's key. Pub/Sub has ordering keys; Service Bus has
  sessions.
- **Delivery**: all of them are at least once by default, which lesson 7 explains. Some offer
  deduplication within a time window, which narrows the duplicates and does not remove them everywhere.
- **Retention**: SQS keeps an unread message for up to 14 days, while a log keeps messages whether or not
  they were read; only the logs let a new reader go back to the start.
- **The exit**: a system built on one provider's queue moves to another provider with a rewrite of every
  producer and consumer; one built on RabbitMQ's or Kafka's protocol moves with a change of address.
