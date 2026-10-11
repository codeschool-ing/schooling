---
title: What a yes costs
version: 1
---

A yes to a request costs more than the hours in its estimate. It also costs the hours the strategy
had already given to something else, and **a strategy that cannot say what those hours were will
lose them, one reasonable request at a time.** This section puts a number on that, using one team's
sprint at Coreto.

On a Thursday in May, Júlia Sato, the head of product, stops by the Checkout team. Coreto's largest
festival client wants group bookings for its next season: one buyer picks a block of seats for a
group of friends, the seats are held together, and each friend pays separately. Mateus Araújo, the
Checkout tech lead, looks at it with two of his engineers and estimates about 90 hours. "That's a
corner of one sprint," Júlia says. "Can you fit it in?"

## The sum everybody does

The sum in the room is the estimate. Ninety hours at Coreto's R$ 150 an engineer-hour is
R$ 13,500, and set against what the festival pays Coreto in ticket fees, that looks cheap. **It is
the right sum for the wrong question.** It prices the feature as though the team had 90 hours
nobody was using, and a team in the middle of a strategy has no such hours.

Start from what the team actually has. Checkout is six engineers, a sprint is ten working days,
and Coreto plans on six focus hours a day per engineer — the rest of the day goes to reviews,
meetings, support questions and the interruptions every team has.

| | Checkout |
|---|---|
| engineers | 6 |
| working days in a sprint | 10 |
| focus hours a day | 6 |
| **capacity in a sprint** | **360 h** |

Six times ten times six is 360 hours. A request of 90 hours is 90 out of 360: **a quarter of a
sprint, 25%.** Put that way, the request is no longer a corner. Each engineer has 60 hours in a
sprint, so 90 hours is one engineer and a half for the whole of it. `delivery-metrics` lesson 12 shows how to measure a team's capacity and why a
plan should leave slack in it; this lesson takes the 360 hours as given.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two bars, each one Checkout sprint of 360 hours. Before: one solid bar, all 360 hours planned for Checkout's move onto the new hold interface. After a yes to group bookings: 270 hours left for the strategy's work and a dashed block of 90 hours for group bookings, a quarter of the sprint, R$ 13,500.\"><rect x=\"30\" y=\"42\" width=\"660\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"28\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">before: one Checkout sprint, 6 engineers × 10 days × 6 focus hours</text><text x=\"360\" y=\"69\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">360 h, all planned: Checkout's move onto the new hold interface</text><text x=\"30\" y=\"120\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">after a yes to group bookings</text><rect x=\"30\" y=\"134\" width=\"495\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">270 h left for the strategy's work</text><rect x=\"528\" y=\"134\" width=\"162\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"609\" y=\"161\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">90 h: group bookings</text><text x=\"690\" y=\"200\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">a quarter of the sprint · R$ 13,500</text><text x=\"30\" y=\"232\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the request is the dashed block; the strategy loses the same 90 h from the solid one</text></svg>", "caption": "The same sprint before and after a yes. The person asking sees the dashed block; what shrinks is the work the strategy had put first."}
```

## Every hour was already promised

The 360 hours are not idle. Coreto's strategy, from lesson 1, gave the reservation module an owner
and asked the new Reservations team to spend two quarters removing the row locks from the hold
path. That work needs Checkout to move its own features onto the hold interface the Reservations
team is building, and **that move is what Checkout's sprints this quarter were planned for.**

So the 90 hours do not come from nowhere. They come out of the move, the move delays the lock
removal, and the lock removal is the first action of a strategy whose guiding policy is "protect
the on-sale first". The cost of the yes, stated in the strategy's own terms, is that the thing the
company decided matters most arrives later.

That delay has a price of its own. Lesson 5 priced the seat-hold debt at 31 hours of interest a
sprint — R$ 4,650 — paid by every team that touches the module for as long as the debt stays.
**If the yes pushes the lock removal back by one sprint, that sprint's interest is part of what
the yes cost**, on top of the R$ 13,500 everybody saw.

## The request collides twice

Group bookings have a second problem, and it is not about hours. Holding a block of seats for a
group means new holds on the reservation path, which is exactly the path the guiding policy
protects: nothing ships to it without evidence from a load test. **The request competes with the
strategy for the same people, and it also asks to change the code the strategy has fenced off.**

A request can collide in either way alone. A feature far from the reservation path still takes
hours from the strategy's work; a two-hour change to the hold logic takes almost no capacity and
still crosses the policy. Check both before answering.

## Small yeses add up

Ninety hours looks like a corner because it is compared with nothing. Compare it with the sprint
and four such requests are the whole of it: 4 × 90 is 360. Nobody agrees to lose a sprint of the
strategy's work. **They agree four times, in four conversations, to something that looked small
each time**, and at the end of the quarter the strategy's dates have moved and no single decision
moved them.

`architect-communication` lesson 8 treated the cost of yes as a capacity problem inside one
conversation, and showed how to make the trade-off visible to the person asking. A strategy adds
the view across conversations. It is the one document that says what all the hours were for, so it
is the only place where the fourth small yes shows up as the one that cost a sprint.

## The yes that is right

None of this makes no the default answer. The strategy is a test, and some requests pass it. Had
Júlia asked for a waiting room in front of checkout for on-sale mornings, the right answer would
have been yes, taken out of other work if necessary, because it protects the on-sale. **A request
that serves the guiding policy gets a yes even when it is inconvenient**; a request that competes
with it gets the answer the next section describes.
