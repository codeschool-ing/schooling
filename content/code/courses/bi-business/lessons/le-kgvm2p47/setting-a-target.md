---
title: Setting a target
version: 1
---

The quickest way to set a target is to take last year's number and add ten percent, or to pick a
round one: 90% on time sounds like a company that delivers. **A target chosen that way says nothing
about what is possible or what is needed**, and people learn quickly to ignore a number that was
never connected to either. A target worth having is built from four things, and a KPI card carries
the result as two numbers rather than one.

## Four sources

**The baseline** is where the KPI stands today, measured with the card's definition. For Caio's KPI
that is the 76.9% of the last section, and it is only a baseline because the definition was fixed
first. A target set before the definition is a target that will be met by changing the definition.

**The history** says how much the number moves on its own. Here are the twelve weeks before that
week, the card's rate for each, from mid-November 2025 to the end of January 2026. Type them into a
new sheet from A1:

| | A | B |
|---|---|---|
| 1 | Week | On promise % |
| 2 | 1 | 78.4 |
| 3 | 2 | 81.2 |
| 4 | 3 | 76.4 |
| 5 | 4 | 83.0 |
| 6 | 5 | 79.5 |
| 7 | 6 | 80.8 |
| 8 | 7 | 74.1 |
| 9 | 8 | 82.6 |
| 10 | 9 | 79.9 |
| 11 | 10 | 81.7 |
| 12 | 11 | 77.3 |
| 13 | 12 | 84.0 |

```localised
=MIN(B2:B13)                 74.1
=MAX(B2:B13)                 84
=MEDIAN(B2:B13)              80.35
=ROUND(AVERAGE(B2:B13),1)    79.9
```

**A normal week sits around 80, and the number wanders between 74 and 84 with nothing changed.** That
range is the most useful fact on this page. A week at 77 is not news; a target of 81 would have been "met"
in five of these twelve weeks by luck; and the 76.9% that started this lesson is an ordinary week, not a crisis.

**The benchmark** is what others achieve. It is worth having and dangerous to copy, because a
competitor's "92% on time" was computed with a definition you have not seen. If theirs leaves out
every cancellation, it is Caio's warehouse figure of 83.3% and not the card's 76.9%, and comparing
the two is comparing two different measures under one name.

**The ambition** is what the strategy needs. Varanda wants the online shop to sell more furniture,
and a customer who waited past the date for a sofa does not order the armchair. Helena wants close
to nine promises in ten kept by the end of the year.

## Two numbers, not one

Put the four together and the card gets a range rather than a point:

- **a goal of 85% by December 2026**, which is above the best week in the history. Reaching it needs
  something to change, a carrier, a route or the way the vans are loaded, rather than a lucky week;
- **an action threshold of 76%, two weeks running**, which is just above the worst week in the history.
  One week below it has happened once in the twelve; two in a row has not happened at all, and is what
  the owner must explain and act on.

Between the two is the normal range, where nobody has to defend anything. **A goal nobody could
reach is a wish, a goal already reached in most weeks is a report, and a threshold inside the normal
range is an alarm that rings every month.** The history is what keeps all three mistakes off the
card.

## The target that is met without delivering faster

Every target creates a second way of reaching it. Caio's carriers could keep more promises by
delivering faster. They could also keep more promises if the promise for furniture went from seven
days to ten, or if orders cancelled after the date were quietly recorded as cancelled before it. Each
of those raises the KPI and leaves the customer exactly where they were.

The card is the first defence, because the definition and the exclusions were written before anybody
had a target to hit, and a change to them is visible and has to be argued. It is not the only one,
and lesson 11 picks this up: what happens to a measure once people are rewarded for it, and the
second number that keeps the first one honest.
