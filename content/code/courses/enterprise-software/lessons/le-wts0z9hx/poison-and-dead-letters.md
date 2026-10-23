---
title: Poison messages and dead letters
version: 1
---

At-least-once delivery has a dark side that the previous sections did not need: a message whose
processing fails is delivered again, and some messages fail every time. **A poison message is one
that can never succeed, however often it is tried**, because the problem is in the message and not
in the world around it. Left alone, it is retried forever, and depending on the queue it either
blocks everything behind it or burns a consumer in a loop. The defence has two parts: retry only as
long as retrying can help, and then move the message somewhere a person will look at it.

## Transient and permanent

The wrong instinct is "retry until it works". It is right for half the failures and harmful for
the other half, so the first job is to tell them apart.

| | examples | does retrying help? |
|---|---|---|
| transient | SAP down for its Sunday window; a database lock timeout; a broker connection dropped; Salesforce refusing a call because a limit was reached | yes: the same message succeeds later, unchanged |
| permanent | malformed JSON; an order for customer 4011873, which does not exist in SAP; a city name longer than the column it goes into; a message in last year's format | no: the hundredth try fails like the first |

A consumer can often tell which is which from the error. A refused connection or a timeout is
transient; a parse error or "customer not found" is permanent. Where it can tell, **a permanent
failure should go straight to the dead-letter queue without spending any retries.** Where it
cannot, a limited number of retries settles it: a transient fault usually clears within them, and a
message still failing at the end is treated as permanent.

What a poison message does when nobody limits it depends on the queue. In a queue read strictly in
order, it sits at the head and **nothing behind it moves**: one bad order holds up every order after
it, which is head-of-line blocking. In a queue with competing consumers, the others carry on, but
one instance at a time is always busy failing. The logs fill with the same stack trace every few
seconds, and the alarm on errors is either constantly on or switched off.

## Retry with backoff, and a ceiling

Retrying immediately is the second mistake. If SAP is refusing calls because it is overloaded,
four consumers retrying at once make it worse. So each retry waits longer than the last, which is
**exponential backoff**: wait 1 second, then 2, then 4, then 8, then 16.

The arithmetic is worth doing once. Five retries with those waits make six attempts in all, and the
total waiting time is 1 + 2 + 4 + 8 + 16 = **31 seconds**. A sixth retry would add 32 seconds, more
than all the earlier waits together, because each wait in a doubling series is one second longer
than the sum of all those before it. That is why backoff runs out of patience quickly, and why the
ceiling is usually set as a number of attempts plus a largest single wait.

Two refinements matter in production:

- **Jitter.** If a broker restart makes 300 messages fail at the same moment, they all retry at 1 s,
  2 s, 4 s, in step, and hit the recovering system as one wave each time. Adding a random part to
  each wait spreads them out.
- **Where the wait happens.** A consumer that sleeps while holding a message holds a consumer slot
  and, with a broker timeout, invites a redelivery. Better brokers can delay a redelivery for you,
  or the consumer republishes the message to a retry queue with a delay and acknowledges the
  original.

When the attempts run out, the message goes to a **dead-letter queue**, and the queue it came from
carries on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l10-backoff\" aria-label=\"A time axis from 0 to 31 seconds. Six attempts, marked at 0, 1, 3, 7, 15 and 31 seconds, all failing. Between them the waits double: 1, 2, 4, 8 and 16 seconds, 31 seconds of waiting in all. After the sixth attempt the message moves to the dead-letter queue, which has an owner, an alarm and a runbook.\"><defs><marker id=\"l10-backoff-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"32.0\" y=\"101.0\" width=\"12.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"38.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 s</text><rect x=\"48.0\" y=\"101.0\" width=\"28.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 s</text><rect x=\"80.0\" y=\"101.0\" width=\"60.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4 s</text><rect x=\"144.0\" y=\"101.0\" width=\"124.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8 s</text><rect x=\"272.0\" y=\"101.0\" width=\"252.0\" height=\"18.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">16 s</text><circle cx=\"30.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"30.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><circle cx=\"46.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"46.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><circle cx=\"78.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"78.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><circle cx=\"142.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"142.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><circle cx=\"270.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"270.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><circle cx=\"526.0\" cy=\"110.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"526.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31</text><text x=\"278.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds since the first attempt</text><text x=\"278.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6 attempts, all failed: 31 s of waiting</text><path d=\"M534.0 110.0 L600.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-backoff-es-ah-amber)\"></path><rect x=\"602.0\" y=\"73.0\" width=\"112.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"658.0\" y=\"103.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dead-letter</text><text x=\"658.0\" y=\"116.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">queue</text><text x=\"658.0\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">owner · alarm</text><text x=\"658.0\" y=\"172.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runbook</text></svg>", "caption": "Exponential backoff: each wait doubles, so five retries cost 31 seconds and a sixth would add 32 more. When the attempts run out, the message is moved aside and the queue carries on."}
```

## Dead letters, product by product

Every family from the first section has the idea, under different names:

- IBM MQ counts in each message's descriptor how many times it was backed out. A queue's
  backout threshold (`BOTHRESH`) and backout requeue queue (`BOQNAME`) tell a reading program, and
  MQ's JMS classes do this for you, to move a message there once the count passes the threshold.
  Separately, each queue manager has a **dead-letter queue**, conventionally
  `SYSTEM.DEAD.LETTER.QUEUE`, where it puts messages it cannot deliver at all, for example to a
  queue that is full or does not exist, with a header that says why.
- RabbitMQ has the **dead-letter exchange**: a queue configured with one forwards a message
  there when a consumer rejects it without requeueing, when its time to live expires, or when the
  queue is over its length limit.
- Amazon SQS has a redrive policy: after a set number of receives without a deletion, the
  message moves to the queue named as its dead-letter queue. Azure Service Bus gives every queue and
  subscription a dead-letter subqueue.
- Kafka has no dead-letter queue in the broker, because a log does not move messages anywhere.
  Consumers, Kafka Connect and frameworks such as Spring write failed records to another topic,
  which is a dead-letter queue by convention.

Hohpe and Woolf (2003) separate two cases that the products blur: a **dead letter channel** for
messages the system could not deliver, and an **invalid message channel** for messages that
arrived and could not be understood. Lesson 11 places both in their catalogue.

## The queue nobody watched

In September 2026 Rui Andrade went through the queue manager under the bus with Joana, queue by
queue, as part of the map lesson 9 began. `SYSTEM.DEAD.LETTER.QUEUE` held **14,386 messages**. The
oldest was from August 2019. Nobody had an alarm on its depth, because nobody had decided it was
anybody's job.

Sorted by origin, they were:

| messages | what they were | why they failed |
|---|---|---|
| 9,870 | customer updates from SAP to Salesforce | a field Salesforce required that SAP left empty for customers created before 2018 |
| 3,214 | delivery confirmations that Rota also received another way | duplicates, harmless |
| 1,279 | acknowledgements from the EDI provider | an old format, from before the provider's 2022 change |
| 23 | credit blocks from SAP to Salesforce | the same missing field as the first row |

The first three rows were noise that should have been fixed or discarded years earlier. The last row
was not noise. **Twenty-three customers blocked for credit in SAP still looked open in Salesforce**,
so the reps went on taking orders from them, and SAP held each order for credit review. The
customer service centre had been answering "where is my order?" calls about those customers for
months, and nobody had connected the calls to a queue.

**A dead-letter queue without an owner is where messages go to be forgotten.** It turns a loud
failure, an error on every retry, into a silent one, which is worse than having no dead-letter
queue at all, because the loud version is at least noticed.

## What makes a dead-letter queue a work queue

Rui and Joana wrote the rule that every flow now follows, new or old:

1. **One dead-letter queue per flow, not one shared by all.** A shared queue mixes messages from
   seventy flows, and its depth means nothing to any of the teams.
2. **A named owner**: the team that owns the consuming system, with a person's name on the flow's
   page, not "integration".
3. **An alarm**: on depth above zero for flows that carry money, stock or credit, and on the age of
   the oldest message for the rest. The age matters more than the count; one message that has sat
   for three weeks is worse than ten that arrived this morning.
4. **A runbook** that says, for that flow, how to read why a message failed, how to fix the cause
   and how to replay the message to its original queue, or how and when to discard it with a
   record of having done so.

Replay is where the earlier sections pay off. A message replayed from a dead-letter queue is a
delivery like any other, possibly the second or third of the same message, so **the consumer it is
replayed to must be idempotent**. And a replay can arrive weeks after newer messages about the same
customer, which is the problem of the last section.
