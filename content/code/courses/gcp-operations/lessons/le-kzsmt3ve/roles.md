---
title: Roles, and telling people what is happening
version: 1
---

**An incident has three jobs, and the danger is one person doing all of them.** Investigating needs
concentration; coordinating needs somebody who is not concentrating on one thing; telling customers needs
somebody who is not trying to fix anything. In a team of two, as the shop is, one person may hold two roles,
but they hold them knowingly and in turn.

| role | does | does not |
|---|---|---|
| incident commander | decides, assigns, keeps the timeline, calls the rollback | type commands |
| operations | investigates and changes the system | talk to customers |
| communications | writes the updates, on a schedule | promise a time to fix |

The commander's most important habit is a question asked every few minutes: "what are we trying now, and when
do we decide it did not work?" Without it, an investigation drifts for an hour on a theory nobody wrote down.

## Updates, on a schedule

Customers and colleagues need to hear something every thirty minutes during a SEV1 or SEV2, **even when there is
nothing new**, because silence reads as "nobody is working on it". An update has four parts and no adjectives:

```localised
14:40 — Investigating. Some payments are failing and being retried; most orders
complete after one retry. We are looking at the connection to the payment
service. Next update at 15:10.
```

What it does not contain: a cause before it is confirmed, a time to fix, or blame. "A problem with our payment
provider" written at 14:40 and wrong at 15:00 is a public statement about another company that has to be taken
back.

## Where the incident lives

One channel per incident, named after it, opened by the commander; one document for the timeline; and the status
page for customers. **Decisions are written in the channel, not made in a call and forgotten**, because the
channel is what the postmortem is written from, and a decision nobody wrote down is a decision the postmortem
cannot examine.
