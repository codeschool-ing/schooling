---
title: By event, saying what happened
version: 1
---

An event is a message that states a fact: *invoice 4711 was authorised*. It is not addressed to
anybody and it does not ask for anything. The system where the fact happened publishes it, and every
system that cares about invoices receives it and decides for itself what to do. **The publisher does
not know who is listening, and does not wait for any of them.** That one property is what the style
is for.

The common misunderstanding is that an event is an API call made asynchronous: the same request,
sent through a queue so that the sender does not wait. That is a real thing, it is called a command,
and it is a different design. The difference is about who decides, and it matters more than the
transport.

## Invoices at Serra Alta, by call

On a weekday Serra Alta issues about 1,400 invoices, and each NF-e has to be authorised by SEFAZ
before the goods leave. When the authorisation comes back, three other systems need to know. Salesforce needs it
so that a key account rep can see the invoice on the customer's record. The Portal B2B needs it so
that a bakery can download its invoice, and the EDI provider so that a supermarket chain's own
system receives it.

Today each of those is its own integration, triggered from SAP's side. When an invoice is authorised,
SAP sends it to an ESB flow, and the flow calls Salesforce's API, writes a row for the portal, and
builds an EDI message, one after another. That is three calls for every invoice, about **4,200 a
day**, and SAP's side knows about all three receivers. When finance asked for invoices in a Power BI
dataset in 2025, it took a change on SAP's side of the flow and a release in the ESB, and the ESB's
release calendar put it four months away. When Salesforce is unavailable, the flow fails part-way:
the portal has the invoice and Salesforce does not, and somebody in Rui's team re-runs the flow by
hand.

## The same invoices, by event

Published as an event, the authorisation becomes one message on a topic, *invoice authorised*, about
1,400 a day. Salesforce's integration, the portal and the EDI flow each subscribe to the topic and
receive every message. **Adding a fourth consumer is a subscription, and the publisher does not
change at all.** Power BI's dataset would have been a new subscriber, built by whoever wanted it, with
nothing to release on SAP's side.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l09-fan-out\" aria-label=\"Two panels. Left, by call: SAP's side sends each authorised invoice to Salesforce, the Portal B2B and the EDI provider, three arrows from one box, and a fourth receiver means a change on SAP's side. Right, by event: SAP publishes one message to the topic invoice authorised, and Salesforce, the Portal B2B and the EDI provider each subscribe to it; a fourth subscriber, Power BI, drawn dashed, is added later without SAP changing.\"><defs><marker id=\"l09-fan-out-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-fan-out-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">by call</text><text x=\"545.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">by event</text><path d=\"M360.0 14.0 L360.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><rect x=\"20.0\" y=\"110.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP</text><rect x=\"210.0\" y=\"53.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Salesforce</text><path d=\"M120.0 130.0 L208.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"210.0\" y=\"113.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M120.0 130.0 L208.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"210.0\" y=\"173.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">EDI provider</text><path d=\"M120.0 130.0 L208.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><text x=\"175.0\" y=\"248.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SAP's side knows all three;</text><text x=\"175.0\" y=\"261.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a fourth is a change there</text><rect x=\"370.0\" y=\"110.0\" width=\"80.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP</text><rect x=\"475.0\" y=\"107.0\" width=\"110.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"123.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">topic</text><text x=\"530.0\" y=\"136.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">invoice authorised</text><path d=\"M450.0 130.0 L473.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"39.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><path d=\"M586.0 130.0 L601.0 55.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"89.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M586.0 130.0 L601.0 105.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"139.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI provider</text><path d=\"M586.0 130.0 L601.0 155.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"189.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Power BI</text><path d=\"M586.0 130.0 L601.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-fan-out-es-ah-paper-dim)\"></path><text x=\"530.0\" y=\"248.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">SAP publishes once;</text><text x=\"530.0\" y=\"261.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a fourth is a subscription</text></svg>", "caption": "The same invoices, sent two ways. With calls, the sender knows every receiver; with an event, it knows only the topic, and Power BI joins without SAP changing."}
```

Failure changes shape too. If Salesforce is down for an hour, its messages wait for it, and when it is
back it works through them. The portal and the EDI flow never noticed. Nobody re-runs anything,
because nothing failed; one consumer was behind.

## Events and commands

A message on a queue can be either kind, and the difference is in what it asks:

| | an event | a command |
|---|---|---|
| example | *invoice 4711 was authorised* | *create customer 30117 in Salesforce* |
| tense | past: it has happened | imperative: do this |
| receivers | any number, unknown to the sender | one, chosen by the sender |
| who decides what happens next | each receiver | the sender |
| what the sender expects back | nothing | that it gets done, and often to hear that it was |

**A command still couples the sender to the receiver's job**: the sender has decided that Salesforce
must create a customer, and if Salesforce's model of a customer changes, the sender's message has to
change with it. A command sent through a queue removes the coupling in time and keeps the coupling in
knowledge. An event removes both, which is also why it fits fewer cases: when the sender needs a
particular thing done, by a particular system, a command is the honest message.

Two shapes of event are worth telling apart, and Martin Fowler's 2017 article *What do you mean by
"Event-Driven"?* names them. An **event notification** carries little more than the fact and an id:
*invoice 4711 was authorised*. A consumer that needs the amount or the customer then calls SAP to ask,
and the coupling in time comes back through that call. **Event-carried state transfer** puts what
consumers need inside the event: the invoice number, the customer, the amount, the NF-e access key,
the items. Nobody calls back, and the event's contents become a contract that SAP's side has to keep,
because consumers it has never met read every field. Serra Alta's invoice event carries the state;
the contract for it is the kind lesson 12 writes down.

## Eventual consistency, in business terms

When the portal learns about an invoice by event, there is a moment when SAP knows the invoice exists
and the portal does not. Normally that is a second or two. Engineers call it **eventual
consistency**: every system will agree, but not at the same instant. The phrase sounds alarming to
people who run a business, and the way to make it ordinary is to say it in their terms:

- A bakery sees its invoice on the portal a few seconds after it was authorised, instead of at the
  same instant. Nobody can tell the difference.
- If the portal's consumer is stopped for a 40-minute deployment, bakeries see no new invoices for 40
  minutes, then all of them at once. Nothing is lost. A bakery that phones in the gap hears from
  customer service that the invoice is being issued.
- The portal shows an order as *confirmed* until the invoice event arrives, and then as *invoiced*.
  For a few seconds two screens in the company disagree, and the later one is right.

What has to be decided is not whether the gap exists but **what each screen says during it**, and
how long a gap is too long. Marcos, the CFO, was untroubled by seconds. He asked what would happen if
the gap were three days, and that is the right question: the failure of an event integration does not
look like an error, it looks like a lag. **The alarm for an event integration is on the age of the
oldest message nobody has consumed**, not on errors, because a consumer that has stopped produces no
errors at all.

## What this lesson leaves to the next one

Everything above treats the broker as a box that keeps messages until consumers take them. How it does that is lesson 10. It covers what a queue and a topic are, what *at least once* delivery
means for a consumer that receives the same invoice twice, and how to publish an event and update
SAP's own database without losing one or the other. It also covers what to do with a message that
can never be processed, and whether the invoices arrive in the order they were issued. Each of those is a way the paragraph above about
nothing being lost can turn out to be false, which is why it gets a lesson of its own.

The style is easy to state and harder to adopt than it looks, because it moves a decision. With
calls, SAP's side decided who got told about invoices. With events, each consumer decides for itself,
and **somebody has to own the topic**: what an invoice event contains, who may publish it, and what
happens when its contract changes. At Serra Alta that owner is now Edson's team, because the fact
happens in SAP.
