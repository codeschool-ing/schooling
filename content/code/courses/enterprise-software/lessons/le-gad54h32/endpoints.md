---
title: Endpoints, where an application meets a channel
version: 1
---

Routers and translators live in the middle of a flow. An *endpoint* is at its edge: the code that
connects an application, which knows nothing about messaging, to a channel, which knows nothing about
the application. Most of the decisions in this group are about **who decides when a message is read,
and what happens to the application's own work if reading it goes wrong.**

The wrong idea to drop is that the endpoint is plumbing, a few lines that call the broker's client
library. Those few lines decide how fast a system is fed, whether two copies of one service share
work or duplicate it, and whether a message survives a crash. The book gives the group eleven
patterns, and they sort into three questions.

## Keeping messaging out of the application

A *messaging gateway* wraps the messaging code behind an interface that speaks the application's
language. Rota, the in-house route planner, publishes each day's truck plan. Its Kotlin code calls
`planPublisher.publish(plan)`; only the class behind that interface knows that a queue manager
exists, what the queue is called, and how a plan becomes bytes. The rest of Rota can be tested
without MQ running, and a change of broker touches one class. The *messaging mapper* is the part of
that class that turns a domain object into a message and back.

A *service activator* is the same idea facing the other way. It takes a service that was written to
be called, and makes it callable by a message. The SAP branch of the order flow ends in one: it reads
a store order off a queue, calls the BAPI `BAPI_SALESORDER_CREATEFROMDAT2`, which creates a sales
order, and puts the result on the reply channel. **The BAPI knows nothing about messages**, and the
same function module goes on being called by other programs in other ways.

Spring Integration uses both names as they are in the book, as `gateway` and `service-activator`,
which is one of the clearest signs of how far the vocabulary travelled.

## Who decides when a message is read

| consumer | who decides when a message is read | fits when |
|---|---|---|
| polling consumer | the application, when it asks | the receiver needs to control its own pace |
| event-driven consumer | the messaging system, when a message arrives | messages should be handled as soon as they come |
| competing consumers | whichever of several consumers is free | one consumer cannot keep up |
| selective consumer | the consumer, by a condition on the message | a consumer wants some messages on a shared channel |
| durable subscriber | the consumer, and the broker keeps what it missed | a subscriber must not lose events while it is down |

A *polling consumer* asks for a message when it is ready for one. The ABAP job that loads Coleta's
file at 02:00 is a polling consumer of a file rather than a queue, and the shape is the same: the
receiver sets the time. **A polling consumer is how a fragile receiver protects itself.** During the
month close, in the first five working days of each month (lesson 1), Edson wants SAP to take store
orders at no more than 50 a minute. A consumer that asks for 50 messages a minute delivers that,
whatever the queue holds.

An *event-driven consumer* is handed each message as it arrives. An IIB flow that starts with an
MQInput node behaves this way from the flow's point of view: the flow runs when a message is there.
It is the natural default for a flow that should react quickly, and it gives the receiver no say in
the pace.

*Competing consumers* are several consumers reading one point-to-point channel, so that each message
goes to one of them. Running three copies of the SAP order flow on the same queue roughly triples what
it can take, and loses the guarantee that orders are processed in the order they arrived. Lesson 10 is
about why that matters and what to do when it does.

A *selective consumer* reads only the messages that match a condition, such as a JMS message
selector `plant = 'ALAGOA'`. Joana's first design for Business Central's side of the order flow used
one: a single order queue, with the Business Central adapter selecting Alagoa's orders and the SAP
side selecting the rest. Rui argued her out of it in ten minutes. **A message no selector matches sits
on the queue for ever and nobody is told**, so a store order from a fifth plant, or a plant code with a
typo, would vanish into a queue that looked healthy. And every consumer pays for the selection on every
message it skips. A content-based router puts the decision in one place and gives it a default exit,
which is the design the order flow has.

A *durable subscriber* is a subscriber to a publish-subscribe channel whose subscription outlives its
connection: the broker keeps the messages published while it was away. The Portal B2B subscribes to
price changes. When it is redeployed and is down for ten minutes, a non-durable subscription would
miss every price change published meanwhile, and bakeries would order at prices that no longer exist.
The cost is the mirror image: **a durable subscriber that never comes back keeps accumulating
messages**, and a retired consumer's subscription has to be removed by somebody who remembers it.

## Surviving failure at the edge

Two patterns in the group are about what happens when an endpoint fails halfway through its work.

The *idempotent receiver* is a receiver that can safely process the same message twice. Lesson 10
covered it in depth, because at-least-once delivery makes duplicates normal rather than exceptional.
It is listed here because it is an endpoint pattern: idempotency is a property of the receiver, not of
the channel.

A *transactional client* makes taking a message and doing the work one unit: if the work fails,
the message goes back on the queue as if it had never been read. On IBM MQ this is a get under
syncpoint, committed only after the work succeeds. The book also uses the pattern on the sending side,
where sending a message is part of the same transaction as the database change that caused it; lesson
10's outbox is the answer when the database and the broker cannot share a transaction.

The trap is to believe a transaction reaches further than it does. The SAP order flow reads the store
order under syncpoint and calls the BAPI. If SAP commits the sales order and the flow then fails before
committing its get, the message goes back on the queue, and the next attempt creates the order a
second time. **SAP's commit is not part of MQ's unit of work, so the transaction protects the message
and not the order.** That is why the order flow is also an idempotent receiver: before creating an
order it checks whether SAP already has one for that chain order number, store and plant.

## Reading an endpoint in a review

Three questions catch most endpoint defects, and each one maps onto a pattern above:

1. Who sets the pace? If nobody can say, the receiver is event-driven by default and has no
   protection on the day the queue holds 40,000 messages after an outage.
2. What happens to a message nobody takes? A selector that matches nothing, a durable subscription
   for a retired system, a queue whose only consumer was switched off: each one keeps messages that
   nobody is waiting for.
3. What does the transaction actually cover? Name every system that changes when the message is
   handled, and ask which of them roll back if the last step fails. Any that do not need an idempotent
   receiver.
