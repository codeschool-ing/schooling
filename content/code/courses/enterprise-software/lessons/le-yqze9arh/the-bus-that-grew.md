---
title: The bus that grew
version: 1
---

Nobody at Serra Alta decided to put business rules in the bus. Each one arrived as a reasonable
request, on a day when the bus was the quickest place to make a change, from a team that needed it
by the end of the month. **A bus grows logic the way a shared table grows columns: one convenient
addition at a time, each defensible, and the sum something nobody would have designed.** Joana
found three such rules in her first fortnight of reading flows. By the end of the inventory in
section 07 of this lesson there were eighteen flows that held one.

## Three rules that live in the pipe

The first is a discount. In 2023 the Portal B2B went live, and the commercial team wanted bakeries
to get 3% off any order above R$ 1,500. The right place for that rule was SAP's pricing, where every
other discount lives, but the SAP team's backlog put it four months out. The flow that carries
portal orders to SAP, `PB2B_ORDER_TO_SAP`, was already being written. Rui's team added the rule in
about thirty lines of ESQL, before the order reached SAP, and the portal launched on time.

In 2025 the commercial team raised the threshold to R$ 1,800. They asked the SAP team, who changed
it in SAP, where they believed the rule lived. The flow kept applying 3% at R$ 1,500 for five
months, until an auditor sampling invoices asked why some orders carried a discount the price list
did not explain. **A rule with two homes is a rule that will disagree with itself**, and nothing in
either system can tell which copy is the real one.

The second is a decision about which plant ships. Supermarket chains send orders by EDI, and the
flow `EDI_ORDER_IN` chooses the plant that fulfils each line: butter from Lavras, milk powder from
Barbacena, and for UHT milk, Juiz de Fora unless the chain's distribution centre is south of a
latitude written into the flow. That is a logistics decision. It belongs with the people who plan
stock and trucks, and it was put in the bus because the bus was the first thing to see the order.

The third is a credit block. When a Salesforce opportunity becomes an order, the flow that creates it in SAP first asks SAP for
the customer's open balance and compares it with the credit limit. If the limit is exceeded, it
sends the order with a delivery block and an email to finance. SAP has credit
management of its own; the rule in the flow and the rule in SAP were set up two years apart by
different people, and they do not use the same limit.

## How to recognise logic in a flow

Moving a message from one place to another is integration. Changing its format is integration.
Deciding something about the business is not, and it is usually visible if you know what to look
for. **A flow carries business logic when a business person could ask for it to change.** Three
signs show it:

- a number in the code that somebody outside IT owns: a threshold, a percentage, a limit, a date;
- a decision a business person would recognise and argue with: which plant, whether to block,
  which price;
- a call to a third system in order to decide, rather than to fill in a field the receiver needs.

By that test, a flow that turns `20261022` into `2026-10-22` carries none, and a flow that drops
orders from customers with an overdue invoice carries a credit policy, however short its code is.

## The team became a queue

The second thing that grew was the wait. Every change to any integration at Serra Alta passes
through Rui's team of four, because they are the only people who know the toolkit, ESQL and the
deployment process, and because a mistake in one flow can stop the engine every other flow runs on.
In October 2026, when Joana counts, **23 change requests are waiting, and the average request has
waited 9 weeks before anybody starts it.** The Rota team waited 11 weeks for one field to be added
to FarmRegistry's response.

None of that is laziness. It is the arithmetic of a shared resource. The team is small, the work
arrives from every project at once, and each change has to be tested against a single shared test
environment where 70 flows live together. The people who know what a change should do — the Portal
team, the Salesforce administrator, the logistics planners — cannot make it, and the people who can
make it have to learn, each time, what it should do. **The central team turns every integration
change into a hand-off, and every hand-off is a queue.** The longer the queue, the more teams find
another way round it: a direct database link, a spreadsheet, a file on a shared folder. Each of
those is the 2014 problem coming back through the side door.

## Smart endpoints and dumb pipes

In 2014 James Lewis and Martin Fowler published an article describing the architectural style
then being called microservices. One of its characteristics was put in a phrase that stuck:
**smart endpoints and dumb pipes.** The logic lives in the services that own the data and the
decisions; what connects them does as little as possible — moves the message, reliably, and
nothing else. They wrote it explicitly as a contrast with the ESB, where the pipe had become the
smartest thing in the building.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l08-logic\" aria-label=\"Two panels. On the left, the bus that grew: the Portal B2B, Salesforce and EDI send to a wide bus, which holds three business rules (a 3% discount above R$ 1,500, which plant ships, a credit block) and passes orders on to SAP ECC. On the right, smart endpoints and dumb pipes: the same three senders put messages on a thin MQ pipe that holds no rules, and SAP ECC holds the three decisions in its own pricing, logistics and credit management.\"><defs><marker id=\"l08-logic-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the bus that grew</text><rect x=\"118.0\" y=\"58.0\" width=\"150.0\" height=\"204.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"193.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ESB</text><rect x=\"126.0\" y=\"91.0\" width=\"134.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"193.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3% above R$ 1,500</text><rect x=\"126.0\" y=\"151.0\" width=\"134.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"193.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">which plant ships</text><rect x=\"126.0\" y=\"211.0\" width=\"134.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"193.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">credit block</text><rect x=\"12.0\" y=\"86.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M100.0 100.0 L116.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"12.0\" y=\"146.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><path d=\"M100.0 160.0 L116.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"12.0\" y=\"206.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><path d=\"M100.0 220.0 L116.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"283.0\" y=\"140.0\" width=\"70.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"318.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP ECC</text><path d=\"M268.0 160.0 L281.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><text x=\"175.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">the rules live in the pipe</text><path d=\"M362.0 40.0 L362.0 296.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"545.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">smart endpoints, dumb pipes</text><rect x=\"382.0\" y=\"86.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"426.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M470.0 100.0 L492.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"382.0\" y=\"146.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"426.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><path d=\"M470.0 160.0 L492.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"382.0\" y=\"206.0\" width=\"88.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"426.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><path d=\"M470.0 220.0 L492.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"494.0\" y=\"70.0\" width=\"16.0\" height=\"180.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"502.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MQ</text><path d=\"M510.0 160.0 L524.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-logic-es-ah-paper-dim)\"></path><rect x=\"526.0\" y=\"82.0\" width=\"184.0\" height=\"156.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"618.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"533.0\" y=\"117.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"618.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pricing: 3% above R$ 1,800</text><rect x=\"533.0\" y=\"155.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"618.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">logistics: which plant ships</text><rect x=\"533.0\" y=\"193.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"618.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">credit management</text><text x=\"545.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the pipe moves messages; the owner decides</text></svg>", "caption": "Where the logic sits. On the left a rule can be changed in SAP and keep running, unchanged, in the bus; on the right each rule has one home, with the team that owns it."}
```

Two misreadings of the phrase are common, and both would hurt Serra Alta.

The first is that *dumb* means *unreliable*. It does not. IBM MQ holding a message until SAP comes
back from its Sunday window is a dumb pipe in Lewis and Fowler's sense: it does not know or care
what is in the message. Reliable delivery, retries at the transport level, routing by a declared
destination and monitoring are all things a dumb pipe does. **What a dumb pipe never does is decide
something about the business.**

The second is that smart endpoints mean no integration team. The work Rui's team does well —
running MQ, setting standards for message formats and security, watching what flows and what is
stuck, knowing what happens when SAP restarts — is needed more, not less, when twelve teams each
own their integrations. What changes is the job: from building every flow to running the platform
the flows run on, and from making changes for other teams to reviewing the changes those teams
make.

## What it costs to leave the logic where it is

Joana writes the case for Regina in three lines, each with a number attached:

| cost | evidence at Serra Alta |
|---|---|
| rules with two homes drift | the discount ran at the old threshold for five months |
| change waits for a team that does not own the rule | 23 requests waiting, 9 weeks on average |
| the bus cannot be upgraded or replaced without re-deciding the business | 18 flows hold rules that would have to be rewritten, and agreed with their owners, before any of them could move |

The third line is the one that decides the future of the bus. A bus that only routes and
transforms can be replaced by another one, or by plain messaging, in months. **A bus that holds
the business's rules can only be replaced by finding the rules a home first**, and that is a
project with the commercial team, logistics and finance in the room, not an integration upgrade.
Section 07 is how to do it.
