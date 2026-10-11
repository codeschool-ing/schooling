---
title: When everything is a priority
version: 1
---

In the planning meeting for the next half-year, four pieces of work arrive at Davi's table, and
each arrives labelled as the priority. Júlia Sato, head of product, brings **Pix in instalments**:
buyers keep asking to split a ticket into monthly payments by Pix, and the sales team hears about
it every week. The festival organisers want **festival seat maps**, so a buyer can pick a spot on a
field the way they pick a seat in a theatre. Ticket resellers are waiting on a **partner API**
to sell Coreto's inventory on their own sites. And Davi has the **seat-hold fix**, the first and
most urgent slice of the debt lessons 1 and 5 kept returning to: the change that stops a hold from
locking rows during an on-sale.

All four need the same people. Every one of them touches the checkout and reservation path, and
the engineers who know that path well enough to change it safely are one group. **The question is
not which of the four matters**, since all four do. It is what order to do them in, and that is a
different question with a different kind of answer.

## Three ways the meeting usually decides

**Some meetings decide by importance.** Each sponsor argues that their item is the most important, and the item with
the most senior or most persistent sponsor goes first. Importance does not order a queue, because
every item in the room is important to somebody; that is how it got into the room.

**Some decide by the loudest customer.** The item somebody complained about most recently goes first. A recent
complaint is evidence of a cost, and it is not a measure of its size: the buyers who asked for Pix
in instalments are visible, and the venues quietly losing on-sales to the seat-hold code are not.

**And some do all four at once.** Nobody has to lose, so the group splits four ways and each item
gets a share of the people. This is the most popular answer and the most expensive, and the arithmetic shows why.

## Why "all at once" costs most

The four items take 25 weeks of the group's time in total: 6, 12, 3 and 4. Done one after another,
the first is finished in a few weeks and starts earning; the last waits until week 25. Run all four
in parallel, each with its share of the people, and **all four finish together, in week 25**. Not
one of them delivers anything until the very end.

Every week an item is not finished costs Coreto something — the next section puts reais on it — and
the four together cost R$ 108,000 a week while they wait. In parallel, the whole R$ 108,000 runs for
all 25 weeks: R$ 2,700,000 of delay (108,000 × 25). The section after next compares three orders,
and the costliest of them comes to R$ 1,794,000; done one at a time, every item but the last finishes
before week 25, so any order at all costs less than running them together. **Splitting the team four ways
is the most expensive way to do the same work**, and the real cost is higher still, because switching between
four pieces of work slows everybody down, which is the subject of delivery-metrics lesson 4.

## The question that orders a queue

Two facts about each item decide its place, and neither is how important it is:

| fact | the question | who knows it best |
|---|---|---|
| cost of delay | how much does it cost Coreto for every week this is not done? | product and the business, with engineering checking |
| duration | how many weeks of the group's time will it take? | engineering |

You have met this pair before. Process-management lesson 12 introduced cost of delay, the four
urgency profiles and WSJF, which divides cost of delay by size, and it estimated both in relative
points. **This lesson does the same arithmetic in reais and weeks.** Money adds two things points
cannot: the cost of a whole order can be added up and compared with another order, and the result
can be set beside anything else the company spends money on, such as the budget lines of lesson 11.

The next section estimates the cost of delay of Coreto's four items.
