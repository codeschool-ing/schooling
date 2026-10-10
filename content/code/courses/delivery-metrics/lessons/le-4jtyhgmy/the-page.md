---
title: One page
version: 1
---

The review the Billing team sends is one page, and the meeting is a conversation about it. People read faster than anybody speaks, so the page goes out the day before, and the half hour is spent on questions rather than on reading slides aloud.

## The shape

```localised
Billing team, July to September 2026

THE HEADLINE
  Work now takes 4 days instead of 23. We release four times as often,
  with no more failures. One incident in September charged 212 cards
  twice; October's features wait for the fixes, as our policy says.

WHAT CHANGED, AND WHY
  1. Cycle time: median 23 days in July, 4 in September; 85th percentile
     33 to 8. Cause: on 3 August we limited work to one item per person
     and put reviews first. We did not finish more items; we finished
     each one sooner.                                     [one chart]
  2. Releases: 5 in July, 20 in September; one failure in each month.
     Fixes now reach the shops within a day.

WHAT WENT WRONG
  30 September: a retry charged 212 cards twice in 167 shops for 54
  minutes; every refund was made by 21:10. Six contributing factors,
  three of them action items from earlier incidents that we had not done.
  The error budget for card charges was 201% spent.

WHAT HAPPENS NEXT
  October: no feature releases to card charges until the budget recovers.
  The idempotency fix, the duplicate-charge alert and the 5% release
  come first. New invoicing screen: all thirty items 85% likely by
  mid-November; the 6 November fair gets the features that are certain.

WHAT WE NEED
  Agreement that October's freeze stands.
  Bia joins the on-call rota; her review work moves to the team.
```

## Why each part is where it is

- **The headline is three sentences**, and somebody who reads nothing else knows the quarter. It carries the good news and the bad news together, because a headline that leaves the incident out loses the room the moment somebody mentions it.
- **Each finding says why**, in one line. A number with no cause invites the wrong one, and the wrong cause for a cycle time that fell is "people worked harder", which would lead the director to the wrong lesson for other teams.
- **What went wrong comes before what is next**, so the asks that follow make sense. Freezing features is unreasonable on its own; after the incident and the budget, it is the obvious step.
- **The forecast is a probability, with a date**, the language of lessons 10 and 11, and the same sentence Bia gave Marta in lesson 11. "85% likely by mid-November" can be believed and checked; "November" can only be hoped for.
- **What we need is specific.** Two asks, each something a person in the room can say yes or no to. A review with no ask is a report; a review with ten asks gets none of them.

## What is not on the page

No velocity, no points, no ticket counts, no numbers per person, no comparison with other teams; lessons 6, 8 and 9 are the reasons. No cumulative flow diagram, which the team reads every day and the director would read once. And no adjectives the numbers do not support: "significantly improved" is a claim, and "23 days to 4" lets the reader decide what to call it.
