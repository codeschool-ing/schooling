---
title: Cost of delay, in reais a week
version: 1
---

Don Reinertsen, in *The Principles of Product Development Flow* (2009), argued that if a team
quantifies one thing about its work, it should quantify the **cost of delay**: how much it costs to
have this later rather than now. Process-management lesson 12 put it in relative points. Here it is
put in money, for one reason: the four items on Davi's table are competing for the same people, and
the comparison has to survive leaving the room.

## Coreto's four estimates

Davi and Júlia sat down with the people closest to each item and asked one question of each: for
every week this is not done, what does Coreto lose? They agreed to answer in reais a week and to
write down what each estimate contains.

| candidate | cost of delay a week | duration | what the estimate contains |
|---|---|---|---|
| Pix in instalments | R$ 48,000 | 12 weeks | fees on the sales lost to buyers who want to pay in instalments and leave for a seller that offers it |
| Festival seat maps | R$ 30,000 | 6 weeks | fees on festival tickets, as organisers choose a platform with seat maps for their next event |
| Seat-hold fix | R$ 18,000 | 3 weeks | the on-sales at risk while holds lock rows, and the interest every team pays on the code |
| Partner API | R$ 12,000 | 4 weeks | fees on the tickets the resellers would sell on their own sites |

**These are estimates, and they are honest about it.** Nobody at Coreto knows the weekly cost of
missing Pix in instalments to the real. What they know is enough to set it beside the other three
with some confidence, and the method needs no more precision than that. Two items whose estimates are close will swap places on a small change in either, and
the next section treats that as a reason to discuss them, not to trust the decimals.

## What goes into an estimate

Three habits make the numbers comparable, which matters more than making them exact.

**One unit for everything.** Reais a week, for every item. An estimate in "customers affected" for
one item and "incidents avoided" for another cannot be put in one queue. The seat-hold fix shows
why this is hard: its cost is risk, a failed on-sale that may or may not happen in a given week.
Davi priced it as an average over the weeks, which is crude; lesson 20 shows how to do that
properly, with a probability and an amount.

**The assumptions written beside the number.** "Fees on lost sales" is checkable after the event;
"strategic value" is not. When the estimate is wrong — and some of these will be — a written
assumption shows which part was wrong.

**Product owns the value, engineering owns the duration.** Júlia's team knows what buyers ask for
and what venues threaten; Davi's knows how long the work takes. Each checks the other, and neither
estimates alone. An engineering team that estimates the cost of delay of its own debt work, with
nobody from product in the room, produces a number product will discount on sight.

## The assumption underneath

The arithmetic in the next section assumes each item's cost runs at a **steady rate** for every week
it waits: R$ 48,000 this week, the same next week, and so on. That is the standard urgency profile
from process-management lesson 12, and it is a reasonable first model for most features.

Not every item has that shape. If the festival organisers sign their contracts for the season on a
known date, festival seat maps are a fixed-date item: nothing is lost until the date, and everything
after it. Such an item is not ranked by the method below; it is scheduled to land before its date,
and the rest of the queue is ordered around it. **Ask about the shape before running the
arithmetic**, because a fixed-date item put through a steady-rate formula comes out in the wrong
place.

## Size alone does not decide

Looking only at the cost of delay, Pix in instalments is the obvious first item: R$ 48,000 a week is
the largest number in the table, and the seat-hold fix, at R$ 18,000, is third. Júlia makes exactly
that argument, and it is a reasonable one.

**It leaves out duration.** Pix takes 12 weeks; the seat-hold fix takes 3. While Pix is being built,
every other item waits twelve weeks; while the seat-hold fix is being built, the others wait three.
The next section puts the two facts together in one number per item, and in that number the
seat-hold fix comes first.
