---
title: Asynchronous: say it and move on
version: 1
---

In the **asynchronous** style the sender hands over a message and carries on without waiting for the
receiver to act on it. Something in between, usually a **message broker** with a queue in it, holds
the message until the receiver takes it. The sender knows the message was accepted by the broker,
not that anybody has done anything about it yet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A producer on the left puts messages into a queue in the middle; a consumer on the right takes them out. The consumer is drawn as stopped, and four messages wait in the queue; the producer keeps working regardless.\"><defs><marker id=\"l5-queue-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l5-queue-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">orders</text><text x=\"105\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">producer, running</text><rect x=\"250\" y=\"80\" width=\"220\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">queue</text><rect x=\"262\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"283\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m1</text><rect x=\"312\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"333\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m2</text><rect x=\"362\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"383\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m3</text><rect x=\"412\" y=\"96\" width=\"42\" height=\"38\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"433\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">m4</text><rect x=\"540\" y=\"80\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"615\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">e-mail</text><text x=\"615\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">consumer, stopped</text><path d=\"M182 115 L248 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-queue-ah-phosphor)\"></path><path d=\"M472 115 L538 115\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l5-queue-ah-wire)\"></path><text x=\"360\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the messages wait; nobody upstream is blocked</text></svg>", "caption": "A queue decouples the two sides in time. The producer does not need the consumer to be up; the messages wait until it is."}
```

The common belief is that asynchronous means faster. **It means decoupled in time**, which is a
different property. Sending a confirmation e-mail through a queue does not make the e-mail arrive
sooner; it makes the order succeed whether or not the e-mail service is up at that moment. The work
still takes as long as it takes, somewhere else.

## What it buys

| property | the synchronous version | the asynchronous version |
| --- | --- | --- |
| the receiver is down | the sender fails too | messages wait in the queue; the sender carries on |
| the receiver is slow | the sender waits | the queue grows; the sender carries on |
| a burst of work | every request waits its turn at the receiver | the queue absorbs the burst and the receiver works through it at its own pace |
| adding a second receiver | the sender has to call it too | it subscribes, and the sender never changes |

The third row has a name in the cloud design patterns: **queue-based load levelling**. A queue between
a spiky source and a steady worker lets the worker be sized for the average rather than for the peak.
Lesson 12 comes back to it, together with what to do when the queue itself fills up.

## What it costs

Everything the synchronous style gave for free has to be thought about again:

- **No answer in the same breath.** The sender cannot tell its own caller "done", only "accepted". If
  somebody needs to know the outcome, it arrives later, by another message or by asking, the next
  section.
- **Delivery.** A broker can lose a message, deliver it twice, or deliver it after a later one,
  depending on how it is configured and how the receiver acknowledges it. Lesson 7 is entirely about
  this.
- **Consistency.** While the message waits, the sender's data and the receiver's disagree. Lesson 9
  shows a customer looking at that disagreement.
- **Following a request.** A synchronous call has a stack trace. A message processed three services
  later, ten seconds after it was sent, has whatever correlation id the sender remembered to put in it.

Lesson 6 builds the brokers themselves, RabbitMQ and Kafka, in your lab. The rest of this lesson stays
with plain HTTP, because one of the most useful asynchronous patterns needs nothing more.
