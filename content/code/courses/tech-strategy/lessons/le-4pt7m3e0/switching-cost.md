---
title: Lock-in is a switching cost
version: 1
---

"We should avoid vendor lock-in" is said in nearly every architecture review, and nobody ever
disagrees with it. **That is the sign it is a slogan.** It sounds like prudence and it decides
nothing, for two reasons. It cannot be followed: every choice locks you into something — a
language, a database, a cloud provider, and, as lesson 8 showed, an open-source engine too. And it
does not say how much avoiding lock-in is worth, so it cannot tell a team when to stop paying for
it.

## A definition that can be used

**Lock-in is the cost of switching away.** Being locked in to a vendor means that leaving would
cost you something — hours of rewriting, data to move, a contract to wait out, people to retrain.
The more it would cost, the more locked in you are. Put that way, lock-in stops being a property a
design has or lacks and becomes a quantity, which can be estimated in hours like any other piece
of work.

Lesson 9 met this cost already, under another name: the exit line of a total cost of ownership is
the switching cost of the option you are about to choose. This lesson takes the same number and
asks what to do about it.

## Coreto's two lock-ins

Davi has two on his list, flagged by two different teams.

**The managed document database.** The Catalogue team keeps each event's page content —
descriptions, line-ups, media, the layout of the venue — in a document database run by Coreto's
cloud provider. It is fast, it needs no operating, and it has its own query interface, which the
Catalogue code calls directly in many places. Leaving it would mean rewriting every one of those
queries against another database, migrating the documents, testing that nothing changed for
buyers, and running both while the move happens. The Catalogue team's estimate is **1,400 hours,
R$ 210,000** at R$ 150 an hour.

**The payment gateway.** Every card payment at checkout goes through one payment gateway, and the
Checkout and Payments code calls its API directly, from the purchase flow to refunds. Leaving it
would mean replacing those calls, re-certifying the payment flows, and moving the stored cards
that let returning buyers pay in one tap. Mateus Araújo, the Checkout tech lead, estimates **900
hours, R$ 135,000**.

The database is the deeper lock-in of the two: R$ 210,000 against R$ 135,000. Most teams would stop
there and worry about the bigger number. The next section shows why that is the wrong place to
stop.

## Four kinds of lock-in

A switching cost has parts, and naming them is how an estimate avoids missing one. Four cover most
cases:

| kind | what makes leaving expensive | at Coreto |
|---|---|---|
| data | volume, a format only the vendor reads, an export that is slow or partial | the event documents; the stored cards at the gateway |
| interface | code that speaks the vendor's own API or query language, in many places | the Catalogue's queries; the gateway calls across checkout |
| contract | notice periods, minimum terms, fees for leaving early | the gateway's contract term |
| skills | people whose knowledge is specific to this vendor | the few engineers who know the database's query model |

**The interface kind is the one a team controls most**, because it is decided in the code, every
time somebody writes a call. Data and contract are decided once, at signing; skills accumulate on
their own.

## What the slogan costs

A team that takes "no lock-in" literally pays for portability everywhere: an abstraction layer
over the database, a wrapper over every cloud service, a refusal of anything proprietary however
useful. Each of those costs hours, every time, for switches that in most cases never happen. And
the team cannot tell which of them were worth it, because it never put a number on the lock-ins it
was avoiding.

With a switching cost written down, the question becomes answerable: **is avoiding this lock-in
cheaper than the lock-in?** That needs two more numbers — how likely the switch is, and what
avoiding the lock-in would cost — and they are the next two sections.
