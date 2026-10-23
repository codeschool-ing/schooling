---
title: Which picture for which question
version: 1
---

**Flow, state and map look alike at a glance — boxes and arrows — and answer three different
questions.** Mixing them up is the most common reason a diagram in this family feels wrong without
anybody being able to say why.

| the question | the picture | the boxes are | the arrows are |
| --- | --- | --- | --- |
| *what happens, step by step, and who does it?* | activity diagram, flowchart, BPMN | steps, things being done | the order of the steps |
| *what states can this thing be in, and what moves it?* | state machine | conditions that last | events that change the condition |
| *which models depend on which, and who adapts?* | context map | bounded contexts, with their teams | upstream and downstream relationships |
| *who sends what to whom, in what order?* | sequence diagram, lesson 2 | participants | messages |

## Telling them apart by their names

The names of the boxes give the diagram away:

- **verbs** — *check departure time*, *refund* — are steps, so the picture is a flow;
- **adjectives and past participles** — *Held*, *Paid*, *Expired* — are states;
- **nouns for areas of the business** — *Sales*, *Fleet*, *Pricing* — are contexts;
- **nouns for running things** — *Ticketing API*, *Booking DB* — are containers, which is lesson 3.

A diagram whose boxes mix verbs and adjectives is two diagrams. *Held → Validating payment → Paid*
puts a step between two states; either *validating* is a state the ticket really stays in, which
should then be named *Awaiting confirmation* and have its own transitions, or it is a step inside the
transition and does not belong on the state machine.

## The same event in three pictures

The late payment from the state-table section appears in all three, differently:

- in the **flow**, it is a decision after *receive webhook*: `[booking expired]` leads to *refund
  automatically*;
- in the **state machine**, it is the transition `payment approved / refund` from *Expired* back to
  *Expired*;
- on the **context map**, it is the line from the payment gateway to Payments: the gateway's model
  of *approved* knows nothing about Carcará's expiry, and translating between them is the ACL's job.

Each picture shows a part of the same fix. Drawing all three is rarely needed; knowing which one the
question needs is the skill.
