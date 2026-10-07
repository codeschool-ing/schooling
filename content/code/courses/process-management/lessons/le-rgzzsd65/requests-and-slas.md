---
title: Service requests and service levels
version: 1
---

Not everything users ask for is a failure. A receptionist who needs an account, a clinic manager who wants a report exported, a physiotherapist who forgot a password: these are **service requests**, defined by ITIL as a request from a user for something that is a normal part of the service. They are handled through a separate practice, **service request management**, with predefined steps, often fully automated, and they should never be logged as incidents. A help desk that treats password resets as incidents ends up with incident statistics that say nothing about failures.

## Agreeing what the service provides

**Service level management** sets clear, measurable targets for the service and checks that they are met. The targets are written in a **service level agreement**, or SLA: a documented agreement between the provider and the customer that says what the service will do and how well. For the Agenda app, an SLA with the clinic network might say:

| measure | target |
|---|---|
| availability of booking, 7:00 to 21:00 | 99.5% of the hours each month |
| priority 1 incidents | worked on within 15 minutes, resolved within 4 hours |
| priority 3 incidents | resolved within 2 working days |
| new user accounts | created within 1 working day of the request |

Behind the SLA sit two other agreements the customer never sees. An **operational level agreement** is between parts of the same organisation — the Agenda team and the infrastructure team, for example — and commits each to the part of the target it controls. An **underpinning contract** is with an outside supplier, such as the hosting provider or the SMS gateway. An SLA promising 99.5% availability on top of a hosting contract that guarantees 99% is a promise the provider cannot keep, and it is worth checking before signing.

## Measuring what users feel

A known weakness of SLAs is the **watermelon effect**: green on the outside, red inside. Every target is met — incidents closed in time, availability above the line — while the users are unhappy, because the targets measure what was easy to measure. Booking may be technically available while taking twenty seconds per screen. Good service level management asks users regularly and adds targets for what they actually experience. An architect can help by designing systems that measure the experience directly, such as the response time of a real booking, rather than the uptime of a server.
