---
title: Three kinds of requirement
version: 1
---

**A requirement is not only a feature somebody wants.** It is anything the system has to do,
anything about how well it has to do it, and anything that has already been decided for it. The
first kind is the one people say out loud. The second decides most of the architecture, and it is
the one they leave out.

The usual picture is a backlog: a list of things the product should let somebody do, written by
product and handed to engineering. That list is real and necessary. It is also the part of the
requirements that tells an architect least, because the same list of features can be built with a
dozen different structures, and what picks between them is almost never on it.

## Functional requirements, quality attributes and constraints

**Functional requirements say what the system does.** A shipper enters an origin, a destination and
a load and gets a price. A driver accepts a load. Payments pays the driver once the delivery is
proved. Each of these is a behaviour you could demonstrate on a screen, and each can be checked by
doing it once.

**Quality attributes say how well it has to do it.** How long the shipper waits for the price. How
many hours a month the booking flow may be down. How long it takes to change the pricing rules
when the ANTT publishes a new floor table. How many shippers can request trucks at the same moment
on the Monday after a holiday. These are the properties lesson 1 called what architecture is for,
and that lesson 6 traded against each other. They are also called non-functional requirements, a
name that makes them sound optional, which is why this course avoids it.

**Constraints are decisions somebody else has already made.** The design does not get to choose
them, only to respect them. At Carreto some come from the law: a quote may not go below the ANTT
minimum freight floor, and a truck may not leave until SEFAZ has authorised the CT-e. Some come
from the company: the money for this quarter, the bank partner Payments already works with, the
six engineers in the Matching team and what they know. Some come from the calendar: the soybean
harvest, which moves more grain through Carreto in February and March than in any other two months.

The three kinds are handled differently. A functional requirement is negotiated with product as
scope. A quality attribute is negotiated as a number, and the number is what costs money. A
constraint is not negotiated by the architect at all; if it hurts, the conversation is with
whoever owns it, and the architect's part is to say what it costs.

## The business states the first and assumes the second

Here is the request Helena Prado, the product director, brought to Renata in her third month as
architect:

> Shippers must be able to quote and book a truck in one go, on one screen. It has to be fast, and
> it has to be always available.

Read it again by kind. "Quote and book a truck in one go, on one screen" is functional, or looks
it. "Fast" and "always available" are quality attributes, and neither is a requirement yet,
because nobody can tell whether a design meets them. And there are constraints Helena did not
mention because to her they go without saying: the ANTT floor, the CT-e, the harvest.

**The unstated quality attributes are the dangerous ones.** Helena did not say that a driver who
taps "accept" must not be told a minute later that somebody else got the load. She did not say
that the booking history must survive the loss of a database server. She left them out because
nobody who has worked in freight for ten years would think of saying them, in the way you would not
tell a builder that the house needs a roof. An engineer who builds only what was said will build
something that meets every sentence of the request and fails in its first week.

So the architect's first job with a request is to **find the second and third kind inside the
first.** Every feature implies qualities: who uses it, how often, at what hours, how many at once,
what happens to them when it fails, how often the rules behind it change. Every feature also lives
inside constraints, and the ones worth finding early are the ones that limit the shape of the
answer.

## The same features, different architectures

Why do the quality attributes matter more to the architecture than the features do? Because **the
features rarely change the structure, and the qualities nearly always do.**

Take Helena's request with two different numbers attached. If "fast" means the price appears in
under two seconds, the work is inside Pricing and the Shipper web app: a cache, perhaps a faster
query, nothing that crosses a team boundary. If "fast" means a driver has accepted the load within
fifteen minutes of the request, the work is in how Matching offers loads to drivers, in the Driver
app, in what the Shipper app shows while it waits, and in the database rule that stops two drivers
taking the same load. The sentence on the backlog is identical. The architecture is not.

This is what Booch's definition from lesson 1 means in practice: the significant decisions are the
ones that are expensive to change. A quality attribute is what turns a feature into an expensive
decision.

## Architecturally significant requirements

Most requirements do not need an architect. A new filter on the shipper's booking list, a column
in a report, the wording of a notification: a team handles these in a sprint and nobody else needs
to know. **An architecturally significant requirement**, the usual name for the other kind, is one
that shapes the structure, so that changing your mind about it later would be expensive.

Four signs mark one, and a requirement needs only one of them:

- **It is expensive to change later.** Who owns which data, whether a flow is synchronous, what has
  to survive the loss of a server.
- **It crosses team boundaries.** At Carreto, anything that touches Matching, the Driver app and the
  Shipper app at once.
- It carries a **strict quality measure**. Fifteen minutes for nine requests in ten is strict; "the
  page should feel quick" is not, yet.
- It carries **high business value or high risk**. Getting it wrong costs customers, money, or a
  conversation with a regulator.

The SEI's Architecture Tradeoff Analysis Method ranks each candidate on two scales at once, its
importance to the business and how hard or risky it is to achieve, each high, medium or low, in a
structure it calls a utility tree. You do not need the tree to use the idea. Placing each
requirement on two axes, business value and architectural impact, is enough to see which handful
deserve the architect's time.

```schooling-figure
@@FIG:l7-grid@@
```

Only the top-right corner gets the full treatment of the rest of this lesson: questions until it
has numbers, a scenario written down, and a line on the one page Helena reads and corrects. The
rest go to the teams that own them, which is where lesson 6 said a decision belongs when it does
not cross a boundary. The price in under two seconds matters a great deal to shippers, and it is
still Pricing's to deliver, inside one service.

**The list is short on purpose.** A system Carreto's size has perhaps a dozen architecturally
significant requirements at any one time, not a hundred. If everything is significant, the label
has stopped selecting anything, and the architect is back to reviewing every feature, which is the
bottleneck lesson 16 draws the role's boundary against.
