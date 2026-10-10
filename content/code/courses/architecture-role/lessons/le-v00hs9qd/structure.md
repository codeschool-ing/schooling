---
title: Structural decisions, and which ones are architectural
version: 1
---

Lesson 5 was about choosing technologies: which database, which library, which managed service.
**The decisions that shape a system most are about structure instead**: how the system is cut into
parts, how the parts talk, and who owns what. They outlive the technologies. Carreto could replace
its message broker with another product next year, and the decision that Payments learns about
proved deliveries asynchronously, from an event, would still stand, with all its consequences.

The wrong idea is that structural decisions are made once, at the start, by whoever drew the first
diagram. **They are made all the time, mostly by teams, and often without anybody noticing that a
structural decision was being made.** A pull request that adds one query against another team's
table is a decision about data ownership, whether its author thought of it that way or not.

## Five kinds of structural decision

The `architecture` course taught the styles these decisions choose between: monoliths and
microservices, synchronous and asynchronous communication, events, sagas. This lesson does not
teach them again. It is about the decisions as decisions: what kind each is, who should take it,
and how to take it well. At Carreto they come in five kinds.

**How the system is cut.** A modular monolith, separate services, or something in between.
Carreto's next piece of work is invoicing shippers once a delivery is paid, and the first
question is whether it becomes a module inside the monolith, which already holds the shipper
records, or a new service owned by Payments. That question is the worked example of this lesson's
third section.

**How the layers depend on each other.** Inside Payments, the code that decides when to pay knows
nothing about the bank partner: it calls an interface, and an adapter behind the interface speaks
the bank's API. That is a layering decision, the same shape as the adapter Pricing uses for its
routing provider in lesson 4, and it is what lets Payments change bank without touching the rules
about money. `design-patterns` lessons 4 and 5 teach dependency inversion and injection, the
techniques underneath it.

**Synchronous or asynchronous.** Whether a caller waits for an answer or hands over a message and
carries on. Record 7 in lesson 5 chose asynchronous for Tracking and Payments, and paid for it with
duplicate and late events. The opposite choice would have tied Tracking's availability to
Payments'.

**Who owns which data.** The question Carreto got wrong for longest. For years the monolith's
`deliveries` table was read and written by the monolith, by Tracking's first version, by a
reporting job and by a script in Payments. Nobody could change a column without asking four teams,
so nobody did, and the table grew fields whose meaning only one person remembered. The decision
Renata pushed for was simple to state: **every piece of data has exactly one owner, the owner is
the only writer, and everyone else asks the owner**, through an API or an event.

**Where a rule lives.** The ANTT minimum freight is checked in Pricing, by the floor stage that is
the only way out. Early on the Shipper app checked it too, in its own code, "to be safe". The two
copies disagreed for a week after ANTT published a new table, because only Pricing loaded it. A
rule with two homes is two rules, and they drift.

## Which decisions are architectural

Not every structural decision needs an architect. Lesson 1 gave the working definition, Booch's:
architecture is the set of significant decisions, where significance is measured by the cost of
change. In practice Renata applies three tests, and a decision that passes any one of them is
architectural:

1. **It is expensive to reverse.** Moving data between owners, splitting a service, or changing
   a public contract takes weeks and a migration, so it gets the care of a one-way door.
2. **It crosses a team boundary.** Its consequences land on a team that did not take it: a new
   event, a changed API, a shared table.
3. **It sets a system-wide quality attribute.** It decides how available, how fast or how secure
   something that several teams depend on will be.

Everything else belongs to the team, and an architect who reaches for it is in the way. **Most
design decisions are not architectural, and that is the point of having a test.** A table of
Carreto's examples makes the line concrete:

| decision | expensive to reverse? | crosses teams? | who decides |
|---|---|---|---|
| Payments' internal module names | no | no | the Payments team |
| which test framework Matching uses | no | no | the Matching team |
| Tracking storing positions in PostgreSQL by month | yes | no | Tracking, with a record and an outside reviewer |
| the fields of the DeliveryProved event | moderately | yes | Tracking and Payments, with Renata |
| invoicing as a monolith module or a new service | yes | yes | Payments and Shipper, with Renata, by the advice process |
| one owner for every table | yes | yes | proposed by Renata, agreed in the architecture forum |

The tests matter more than the table, because the table will be wrong about the next decision.
**A decision moves between rows when its consequences move.** Matching's cache of Pricing's
quotes in lesson 4 started on the first line, internal to one team, and moved up the moment it
could break Pricing's guarantee.

## The decisions nobody takes

The hardest structural decisions to manage are the ones that happen by accumulation. Nobody
decided that the `deliveries` table should have five writers. One script was added in a hurry,
then a reporting job, then a shortcut during an incident, each reasonable on its day. Lesson 17
calls the result accidental architecture: a structure that was never chosen, only arrived at.

**Part of the architect's job is noticing a structural decision while it is still small.** Renata
reads pull requests that touch shared tables, event schemas and public APIs, not to approve them
but to recognise when one of them is quietly deciding something. When she sees one, she does not
block it. She names it in the review ("this makes Pricing a second writer of the deliveries table;
is that the decision we want?") and lets the team decide with the decision in view. Lesson 9 shows
how the most important of these lines can be checked by a program instead of by her attention.

## A decision is not a diagram

One more thing to separate. A structural decision is often drawn, and the drawing is not the
decision. Lesson 2 made the general point; here it is concrete. The diagram of the 24-hour payout
in lesson 4 shows an arrow from Tracking to Payments. **The decision is everything the arrow does
not say**: that it is an event rather than a call, that Payments must tolerate duplicates, that
the fields are a contract, that a nightly check covers lost messages. Those sentences live in
record 7, and the arrow only points at them.

The next section is about the hardest part of these decisions to get right: they always trade one
quality for another, and a vague trade cannot be argued about.
