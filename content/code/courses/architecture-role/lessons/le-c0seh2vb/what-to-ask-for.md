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
fifteen minutes of the request, the work is in how Matching offers loads to drivers and in the
Driver app. It is also in what the Shipper app shows while it waits, and in the database rule that
stops two drivers taking the same load. The sentence on the backlog is identical. The architecture is not.

This is what Booch's definition from lesson 1 means in practice: the significant decisions are the
ones that are expensive to change. A quality attribute is what turns a feature into an expensive
decision.

## Architecturally significant requirements

Most requirements do not need an architect. A new filter on the shipper's booking list, a column
in a report, the wording of a notification: a team handles these in a sprint and nobody else needs
to know. **An architecturally significant requirement**, the usual name for the other kind, is one
that shapes the structure, so that changing your mind about it later would be expensive.

Three signs mark one, and a requirement needs only one of them:

- **It is expensive to change later.** Who owns which data, whether a flow is synchronous, what has
  to survive the loss of a server.
- **It crosses team boundaries.** At Carreto, anything that touches Matching, the Driver app and the
  Shipper app at once.
- **Its quality measure shapes the structure.** Fifteen minutes for nine requests in ten reshapes how
  Matching works; a price in under two seconds is met inside Pricing, however strict the number.

A fourth sign says how soon it deserves attention rather than whether it is architectural: **high
business value or high risk**, where getting it wrong costs customers, money, or a conversation with
a regulator.

The SEI's Architecture Tradeoff Analysis Method ranks each candidate on two scales at once, its
importance to the business and how hard or risky it is to achieve, each high, medium or low, in a
structure it calls a utility tree. You do not need the tree to use the idea. Placing each
requirement on two axes, business value and architectural impact, is enough to see which handful
deserve the architect's time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A grid with business value on the vertical axis and architectural impact on the horizontal axis. The top-right corner, high on both, is marked architecturally significant and holds three requirements: a driver commits within 15 minutes, a delivery proof is recorded with no signal, and bookings survive a lost server. Outside it: the price shown in under 2 seconds (high value, low impact), a second bank for payouts (high impact, lower value), a new filter on the booking list and exporting bookings to a spreadsheet (low on both).\"><defs><marker id=\"l7grid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"390\" y=\"40\" width=\"300\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><path d=\"M390 40 L390 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><path d=\"M90 170 L690 170\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><path d=\"M90 300 L90 32\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7grid-ah)\"></path><path d=\"M90 300 L698 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7grid-ah)\"></path><text x=\"90\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">business value</text><text x=\"690\" y=\"342\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">architectural impact</text><text x=\"100\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">low</text><text x=\"680\" y=\"318\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">high</text><text x=\"82\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">high</text><text x=\"82\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">low</text><text x=\"680\" y=\"58\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">architecturally significant</text><circle cx=\"420\" cy=\"88\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"432\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">driver commits within 15 min</text><circle cx=\"430\" cy=\"117\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"442\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">delivery proof with no signal</text><circle cx=\"402\" cy=\"146\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"414\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">bookings survive a lost server</text><circle cx=\"120\" cy=\"80\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"132\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">price shown in under 2 s</text><circle cx=\"420\" cy=\"225\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"432\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a second bank for payouts</text><circle cx=\"150\" cy=\"212\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"162\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">new filter on the booking list</text><circle cx=\"110\" cy=\"262\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"122\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">export bookings to a spreadsheet</text></svg>", "caption": "Carreto's candidate requirements placed by business value and architectural impact. Only the top-right corner gets the architect's full attention; the price in under two seconds matters a great deal to shippers and still stays inside one team."}
```

Only the top-right corner gets the full treatment of the rest of this lesson now: questions until
it has numbers, a scenario written down, and a line on the one page Helena reads and corrects. The
bottom-right corner is architectural too, and waits its turn. The left half goes to the teams that
own it, which is where lesson 6 said a decision belongs when it does not cross a boundary. The price in under two seconds matters a great deal to shippers, and it is
still Pricing's to deliver, inside one service.

**The list is short on purpose.** A system Carreto's size has perhaps a dozen architecturally
significant requirements at any one time, not a hundred. If everything is significant, the label
has stopped selecting anything, and the architect is back to reviewing every feature, which is the
bottleneck lesson 16 draws the role's boundary against.
