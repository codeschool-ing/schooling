---
title: Commands, events and queries
version: 1
---

A message between services is one of three kinds, and confusing them is where many designs go wrong.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three message kinds in three rows. A command, PlaceOrder, goes from the checkout to the orders service, one named receiver, and asks it to do something. An event, OrderPlaced, goes from orders to anyone listening and states that something happened. A query, GetStock, goes to stock and expects an answer back.\"><defs><marker id=\"l5-kinds-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">command</text><rect x=\"130\" y=\"44\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">PlaceOrder</text><path d=\"M282 60 L348 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-kinds-ah-wire)\"></path><rect x=\"350\" y=\"44\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one receiver, asked to act</text><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">event</text><rect x=\"130\" y=\"114\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">OrderPlaced</text><path d=\"M282 130 L348 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-kinds-ah-wire)\"></path><rect x=\"350\" y=\"114\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">anyone listening, told it happened</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">query</text><rect x=\"130\" y=\"184\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">GetStock</text><path d=\"M282 200 L348 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-kinds-ah-wire)\"></path><rect x=\"350\" y=\"184\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one receiver, an answer expected</text></svg>", "caption": "A command names one receiver and asks; an event names none and tells; a query asks and waits for the answer."}
```

| kind | grammar | who it names | what the sender expects |
| --- | --- | --- | --- |
| **command** | imperative: `PlaceOrder`, `ChargeCard` | one receiver, which may refuse | that the receiver acts, or says why not |
| **event** | past tense: `OrderPlaced`, `PaymentDeclined` | nobody; whoever is interested listens | nothing; it is a statement of fact |
| **query** | a question: `GetStock`, `GetPrice` | one receiver | an answer, and no change to anything |

The grammar is not decoration. **An event states something that already happened and cannot be
refused**: by the time `OrderPlaced` is published the order exists, and a listener that does not like
it can react, for example by sending a command of its own, but cannot make it not have happened. A
command can be refused, and the sender has to be ready for that.

## Who depends on whom

The deeper difference is the direction of the dependency. With a command, **the sender knows the
receiver**: the checkout knows there is a payments service and what to ask it. With an event, **the
receiver knows the sender**: the e-mail service knows that orders publishes `OrderPlaced`, and the
orders service does not know the e-mail service exists. Adding a loyalty-points service that also
listens to `OrderPlaced` changes nothing in orders.

That is why events are the usual way to keep services independent: a service publishes what happened
in its own domain and lets others decide what it means for theirs. It is also how a design gets out of
hand, because nobody can see the whole flow by reading one service. Lesson 14 calls the event-driven
version **choreography** and the command-driven one **orchestration**, and builds a saga each way.

## Which style each kind travels in

| kind | usual style |
| --- | --- |
| query | synchronous: the caller needs the answer to go on |
| command | either: a synchronous call when the caller needs the outcome now, a message on a queue when it can wait |
| event | asynchronous: published once, consumed by any number of listeners, whenever they are ready |

**Do not query over a queue to avoid a dependency**: a question sent as a message and an answer awaited
on another queue is a synchronous call with more moving parts, and it still fails when the other side is
down. It only hides that it does.
