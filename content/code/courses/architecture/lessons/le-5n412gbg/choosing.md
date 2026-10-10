---
title: Choosing between them
version: 1
---

| | orchestration | choreography |
| --- | --- | --- |
| where the plan lives | in one place, the orchestrator | nowhere; in the sum of the listeners |
| "what happened to this order?" | the orchestrator's record | logs from every service, joined by a correlation id |
| adding a step | change the orchestrator | add a listener; nothing else changes |
| coupling | the orchestrator knows every service | each service knows the events it reacts to |
| a cycle or a forgotten compensation | visible in one file | possible, and found in production |
| a new single point of failure | the orchestrator, unless it is replicated | none |

The usual advice, from people who have run both: **choreography for a few steps that rarely change, and
orchestration once a process has more than three or four steps, branches, or compensations**. A
checkout is usually past that line. The lab's three-step choreography is already harder to follow than
its orchestrated twin, and every step added makes the difference larger.

They also mix well. A common shape is an orchestrator for the checkout, the process the business cares
about and support asks about, which publishes `OrderCompleted` when it is done; and choreography for
everything that merely reacts to that, such as loyalty points, recommendations and the e-mail.

Whichever runs it, the saga needs what earlier lessons built: idempotent steps from lesson 7, so a
retried step does nothing twice; timeouts, retries and breakers from lesson 11, so a slow service does
not leave sagas waiting for ever; and an outbox, so that a step's change and the event announcing it are
written together.

When you are done, stop the lab:

```sh
docker compose down
```
