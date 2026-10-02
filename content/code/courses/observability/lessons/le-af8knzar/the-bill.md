---
title: The bill, the exit, and choosing
version: 1
---

A hosted product's bill is the cost tables of lessons 6, 10 and 12 with a price on each row. **The
surprise is rarely the price. It is the unit**, and a habit that is free in your own stack becoming
expensive in somebody else's:

| unit | the habit that makes it grow | where this course met it |
|---|---|---|
| hosts or containers | autoscaling, short-lived workers, one sidecar per pod | lesson 5's node exporter, one per machine |
| custom metric series | a label with a user id or an order id in it | lesson 6's cardinality |
| gigabytes of logs ingested | a debug level left on, a whole object per line | lesson 10's leak and lesson 8's volume |
| indexed spans or events | keeping every trace, retrying failures | lesson 12's sampling |
| users | giving everybody on call a full seat | lesson 18's rota |

Each one has the same defence, and it is the one this course has taught for the free stack: **decide
what to keep before sending it**. The Collector is where that is cheapest, because a span dropped
there was never billed, and a series never created never had to be deleted.

**The exit costs less than it used to, and still costs.** With OpenTelemetry in the services, leaving
a vendor is a change of exporter. What does not move are the dashboards, the alert rules and the
saved searches, written in each product's own query language, and the history, which stays where it
was stored. A team that uses a vendor for two years should expect to rebuild those, and can make that
cheaper by keeping its alert rules close to PromQL and its dashboards few.

**Choosing** is then a short list of questions, and the answers differ by team rather than by
product:

- **Who would run the open-source stack?** If the answer is *nobody in particular*, that is the
  answer. The stack fails the night it is needed.
- **What volume, in the product's own unit?** Measure it, as the stand-in did, before asking for a
  quote, and ask for the quote at twice the volume.
- **Where is the data stored, and under what contract?** Under the LGPD a vendor abroad is a
  transfer, and personal data reaches traces and logs more often than anybody plans.
- **What is only available with the vendor's own agent?** That is the lock-in that remains.

A common result is a mixture. Metrics and logs go in a self-run stack where the volume is high and
the use is routine, and a hosted product takes the part that is hardest to run well, often error
tracking or traces. **The Collector makes the mixture cheap**, which is the strongest argument for
putting one in front of whatever you choose.