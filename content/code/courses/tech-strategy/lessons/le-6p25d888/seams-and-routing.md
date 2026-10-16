---
title: Seams, routing and the data in between
version: 1
---

A strangler migration is a sequence of small moves. Each move has the same three questions behind
it: **where to cut, how to send traffic across the cut, and what to do about the data on both
sides.** Coreto's seat holds answer each one in a way that generalises.

## Find the seam, or make one

A seam is a place where behaviour can be redirected without rewriting everything around it. The best
seams have a narrow interface: few operations, clear inputs, clear answers. Seat holds have one of
the narrowest in `coreto-core`. A buyer's seat is held, then either confirmed when the payment
succeeds or released when it fails or the time runs out. Hold, confirm, release.

The trouble was that nine years of features called the reservation module from everywhere. Checkout
called it one way, the Box Office app another, Mobile through a helper of its own, and two reports
read its tables directly. **The seam existed on a whiteboard and not in the code.** So the Reservations
team's first month went on making it real inside the monolith: every caller changed to go through one
entry point with the three operations, and nothing behind it changed at all.

That month shipped no new service. It still paid for itself, because it gave the team one place to
review every change to seat holds — the review rule lesson 1 asked for — and one place for the facade
to sit.

## Route by the thing that must not be split

With a seam in place, the facade decides which code answers. The choice that matters is the routing
key, the thing the facade looks at to decide. A percentage of requests is the usual default, and for
seat holds it would have been a disaster: two requests for the same seat could reach two different
stores, and two buyers could each be told the seat was theirs.

So Coreto routed by event. All the holds for one event live on one side, and moving an event means
changing one row in the facade's routing table. The order of events was chosen by risk:

- small venues first, where a mistake would touch a few hundred seats;
- then mid-size events, once a few weekends had gone cleanly;
- big on-sales only after the new service had passed the Platform team's on-sale load test, because
  lesson 1's policy says nothing ships to the reservation path without load evidence.

**An event moves before its on-sale opens, never during one.** A move during an on-sale would split
the event's holds across two stores in the middle of the busiest half-hour it will ever have. And
every move is reversible the same way it was made: one row changed back, before the next on-sale.

## Shadow before switch

Before an event was routed for real, the facade sent a copy of each of its hold requests to the new
service as well — **shadow traffic**. The old code still answered the buyer; the new service's answer
was recorded and compared with the old one, then thrown away. Shadow holds went to a separate store
that no buyer ever saw.

Comparing the two answers found what lesson 6 said the old code would hide. The new service at first
ignored a limit on how many half-price student tickets one event may sell, a rule that lived as a
single condition in the old module and in no document. Shadow traffic caught the difference on a
small event, weeks before any buyer could have met it.

## One owner for each piece of data

Seat holds themselves are easy to move, because they last minutes: when an event moves, its new holds
go to the new store and the old ones simply expire. The hard part is everything that reads the result.
Box Office screens, the nightly sales report and the Data team's pipelines all read confirmed seats
from `coreto-core`'s tables, and they could not all change on the day the first event moved.

The tempting fix is the dual write: each confirmation is written to both stores in the same request.
It fails in the gap between the two writes. One succeeds, the other times out, and the two stores now
disagree about who owns a seat, with nothing to say which is right.

Coreto used a stricter rule instead: **for each event, exactly one store is the source of truth at any
moment**, and the other copy is derived from it. For a moved event, the new service owns the holds and
the confirmations, and it publishes each confirmation into the old tables so that existing readers
keep working. A reconciliation job compares the two copies every night and reports any seat they
disagree about. A difference is a bug to fix, and the owner's copy wins.

## The techniques, side by side

| technique | what it buys | what it costs |
|---|---|---|
| a seam inside the old system | one place to cut and to review | a month with nothing new to show |
| routing by event | holds for one event never split | a routing table to maintain and audit |
| shadow traffic | differences found before buyers meet them | double load on the new service, a store to discard |
| one source of truth, a derived copy | readers keep working while they migrate | a publishing path and a nightly reconciliation |

Each of these is temporary scaffolding, there to be taken down. The next section is about taking it
down, which turned out to take a third of the migration.
