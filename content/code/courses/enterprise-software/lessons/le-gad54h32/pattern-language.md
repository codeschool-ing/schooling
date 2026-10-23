---
title: A pattern language for messages
version: 1
---

Ask Rui what the supermarket order flow does and he opens the IBM Integration Toolkit and reads it
out: an MQInput node, a Compute node, a SAPRequest node, a second Compute node, an AggregateControl
node, a Route node, an AggregateReply node, an MQOutput. Every word is accurate and none of it says
what the flow is for. Joana needed the other description: **the
flow translates a chain's order, splits it per store, sends each part to the system that sells it,
and gathers the replies into one confirmation.** The second description is written in the vocabulary
this lesson teaches.

Gregor Hohpe and Bobby Woolf published it in 2003, in *Enterprise Integration Patterns*
(Addison-Wesley). You met the book's first chapter in lesson 9, where its four integration styles
sorted Serra Alta's 110 integrations. The rest of the book is about one of those styles, messaging,
and it names 65 patterns: the recurring shapes that appear whenever applications exchange
messages, whatever product carries them.

The common misreading is to treat the book as a parts catalogue, a list of components to buy or
a list of terms to learn by heart. Neither helps much. **The patterns are worth knowing because they
let you describe a flow in a sentence and then ask the questions that sentence implies.** A flow
described as "splits, routes, aggregates" invites the question *when is the aggregate complete?* A
flow described as "Compute, Route, AggregateReply" invites nothing.

## What a pattern language is

The term comes from architecture of the other kind. Christopher Alexander and his colleagues
published *A Pattern Language* in 1977: 253 patterns for towns and buildings, each one naming a
problem that keeps recurring and the core of a solution to it. Two things made it a *language* rather
than a list. Every pattern had a name short enough to use in conversation. And every pattern pointed
at the smaller patterns that complete it, so that a design could be written as a sequence of names.

Software borrowed the form. The design patterns you studied in `design-patterns` come from the
same tradition, through Gamma, Helm, Johnson and Vlissides in 1994. Hohpe and Woolf applied it to
the space between applications. Each of their patterns has a name, an icon, the problem it answers,
the forces that make the problem hard, the solution, and pointers to the patterns that usually come
next. The pointers matter as much as the patterns: an aggregator is almost always preceded by a
splitter or a recipient list, and the book says so.

## How the book is arranged

The 65 patterns fall into groups, and the groups are a map of the questions any messaging design
has to answer.

| group | the question it answers | patterns in it, for example |
|---|---|---|
| integration styles | how do two applications share data at all? | file transfer, shared database, remote procedure invocation, messaging (lesson 9) |
| messaging systems | what are the parts of any messaging solution? | message channel, message, pipes and filters, message router, message translator, message endpoint |
| messaging channels | how does a message travel? | point-to-point channel, publish-subscribe channel, dead letter channel, guaranteed delivery (lesson 10) |
| message construction | what does a message carry, and what kind of message is it? | command, document and event message; request-reply; return address; correlation identifier; message expiration |
| message routing | where does a message go? | content-based router, splitter, aggregator, routing slip, process manager |
| message transformation | what shape does it arrive in? | envelope wrapper, content enricher, claim check, canonical data model |
| messaging endpoints | how does an application connect to a channel? | messaging gateway, polling consumer, competing consumers, idempotent receiver |
| system management | how do you run, watch and fix it? | control bus, wire tap, message history, message store |

The second group is the root of the rest. **A messaging solution is a chain of small steps joined by
channels**, which is the architectural style the book calls *pipes and filters*: each filter does one
thing to a message and passes it on through a pipe to the next. A router is a filter that decides
where a message goes without changing it. A translator is a filter that changes the message without
deciding where it goes. Everything in the routing and transformation groups is a more specific
version of those two.

Lesson 10 already covered the channels in depth, including what at-least-once delivery means and how
an idempotent receiver survives it. This lesson takes the four groups after construction: routing,
transformation, endpoints and system management.

## The notation

Each pattern has an icon, and a flow is drawn as icons joined by channels. The book's icons are
published on its website, enterpriseintegrationpatterns.com, along with a short description of every
pattern. The figure uses simplified versions of six of them; the real ones are more detailed, and
any whiteboard version that keeps the shapes distinct works.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 186\" role=\"img\" data-fig=\"l11-notation\" aria-label=\"Six simplified icons in the notation of Enterprise Integration Patterns, each with its name and how many messages go in and come out. Message channel: a tube that carries messages. Message: a small block with a header band on top of the body. Content-based router: one line in, forking to three outputs; one message in, one out on one of several channels. Message translator: a square in, a circle out; one in, one out, changed. Splitter: one large block in, three small ones out; one in, many out. Aggregator: three small blocks in, one large one out; many in, one out.\"><rect x=\"33.0\" y=\"41.0\" width=\"54.0\" height=\"14.0\" rx=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><path d=\"M80.0 41.0 A 4 7 0 0 0 80.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\"></path><text x=\"60.0\" y=\"93.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">message</text><text x=\"60.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">channel</text><text x=\"60.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">carries messages</text><rect x=\"167.0\" y=\"38.0\" width=\"26.0\" height=\"20.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><rect x=\"167.0\" y=\"38.0\" width=\"26.0\" height=\"6.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"180.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">message</text><text x=\"180.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">header + body</text><rect x=\"273.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M280.0 48.0 L296.0 48.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M296.0 48.0 L318.0 37.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M296.0 48.0 L318.0 48.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M296.0 48.0 L318.0 59.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"300.0\" y=\"93.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">content-based</text><text x=\"300.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">router</text><text x=\"300.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 in, 1 out of n</text><rect x=\"393.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"401.0\" y=\"43.0\" width=\"10.0\" height=\"10.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M414.0 48.0 L424.0 48.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"433.0\" cy=\"48.0\" r=\"5.5\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></circle><text x=\"420.0\" y=\"93.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">message</text><text x=\"420.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">translator</text><text x=\"420.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 in, 1 out, changed</text><rect x=\"513.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"520.0\" y=\"39.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><path d=\"M534.0 48.0 L548.0 37.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"549.0\" y=\"33.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M534.0 48.0 L548.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"549.0\" y=\"44.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M534.0 48.0 L548.0 59.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"549.0\" y=\"55.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">splitter</text><text x=\"540.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 in, many out</text><rect x=\"633.0\" y=\"29.0\" width=\"54.0\" height=\"38.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"643.0\" y=\"33.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M652.0 37.0 L666.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"643.0\" y=\"44.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M652.0 48.0 L666.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"643.0\" y=\"55.5\" width=\"8.0\" height=\"7.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><path d=\"M652.0 59.0 L666.0 48.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"668.0\" y=\"39.0\" width=\"12.0\" height=\"18.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.3\"></rect><text x=\"660.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aggregator</text><text x=\"660.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">many in, 1 out</text><text x=\"360.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">a flow is drawn as these icons joined by channels; the count of messages in and out is what each icon promises</text></svg>", "caption": "Six of the 65, simplified from the book. Each icon promises how many messages go in and how many come out, which is what makes a drawn flow checkable by counting."}
```

The notation has one property that box-and-arrow diagrams lack. **Every icon makes a promise about
how many messages go in and how many come out.** A translator is one in, one out. A router is one
in, one out, on one of several channels. A splitter is one in and many out. An aggregator is many in
and one out. So a diagram in this notation can be checked by counting, which is exactly what Joana
does with Rui's flow in this lesson's section on composing.

## What travels: a message

A message has two parts. **The header is for the messaging system and the flow; the body is for the
receiving application.** The header carries identifiers, timestamps, the type of the message and
where a reply should go. The body carries the business data and nothing about transport.

Here is one of the messages Rui's order flow produces, written as JSON for reading. On IBM MQ the
header fields live in the message descriptor and in message properties rather than in a JSON object,
but the division is the same.

```json
{
  "header": {
    "messageId": "c41e9a6b-2f07-4d5e-9b1a-08d2f6e3a7c5",
    "correlationId": "VV-2026-118342",
    "replyTo": "ORDER.CONFIRM",
    "type": "PlaceStoreOrder",
    "sequence": 3,
    "sequenceSize": 21,
    "sentAt": "2026-10-19T05:42:10-03:00"
  },
  "body": {
    "store": "7898357410015",
    "plant": "LAVRAS",
    "lines": [
      { "gtin": "7898357412019", "cases": 48 },
      { "gtin": "7898357412033", "cases": 12 }
    ]
  }
}
```

The store is identified by its GLN, the 13-digit location number GS1 issues, and the products by
their GTIN, the number under the barcode. Both are fictional here.

### Three kinds of message

The book separates messages by what the sender intends, because the intention changes the contract
even when the channel is identical.

| kind | what it says | at Serra Alta |
|---|---|---|
| command message | do this | *create this store order in SAP* |
| document message | here is some data; what you do with it is your business | the monthly price table sent to the Portal B2B |
| event message | this happened | *batch 2614 released by quality* |

A command has one intended receiver and the sender expects it to be carried out. An event is sent
without knowing who listens, or whether anybody does. Mixing the two is a common source of trouble:
**an event named like a command, `CreateDelivery`, invites one subscriber to treat it as an order
while another treats it as news**, and nobody owns the outcome.

### Correlation identifier and return address

Two header fields come up in every flow that expects an answer.

The *return address* is the channel the reply should be sent to, carried in the request. Without
it, the receiver has to know who called it, which couples it to every caller. In the message above it
is `replyTo`.

The *correlation identifier* is carried in the reply and names the request it answers. It is a
different thing from the message id. **The message id identifies this message; the correlation id
says what this message belongs to.** When the 21 replies of an order arrive at the aggregator in any
order, mixed with replies for other orders, the correlation id is the only thing that sorts them.

The book defines the correlation identifier for request and reply. In practice the same field is
stretched to tie together every message of one business transaction, and Serra Alta's flows carry the
chain's order number in it from the first message to the last. This lesson's section on system management
shows what happens to a trace when no such number exists.

Both fields are in the products under the book's names or close to them. IBM MQ's message descriptor
has `MsgId`, `CorrelId` and `ReplyToQ`; the Java Message Service has `JMSMessageID`,
`JMSCorrelationID` and `JMSReplyTo`. When you see them, you are looking at the patterns.
