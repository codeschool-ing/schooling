---
title: MoSCoW
version: 1
---

**MoSCoW** sorts requirements into four groups. Dai Clegg devised it at Oracle in 1994, and it became part of the Dynamic Systems Development Method, DSDM, one of the methods represented at the 2001 meeting that wrote the agile manifesto. The lower-case letters are only there to make it pronounceable.

- **Must have**: without it, the release is pointless or illegal. If a must-have will not be ready, the release does not go ahead.
- **Should have**: important and expected, but there is a workaround, even a painful one.
- **Could have**: desirable; left out first if time runs short.
- **Won't have this time**: agreed to be out of this release. Writing it down is the point: it stops the item being assumed.

## The rule that makes it work

The categories are useless if everything is a Must, which is what happens when people who want their item built are asked to label it. DSDM's guidance adds a budget: **must-haves should be no more than about 60% of the effort**, and could-haves around 20%. The could-haves are the contingency: when the estimate runs over, they are dropped, and the must-haves still arrive on the date.

For the Agenda team's online-booking release, a MoSCoW pass might read:

| group | items |
|---|---|
| Must | patients can book and cancel; receptionists see the bookings; payment of the deposit |
| Should | SMS reminders the day before |
| Could | reports for clinic owners; recurring appointments |
| Won't, this time | a native mobile app; integration with the clinics' accounting software |

## What it does and does not do

MoSCoW is good at one thing: **agreeing scope for a fixed date**, which is why it fits DSDM's fixed-time, variable-scope projects and the contracts of lesson 1 that fix the budget and the date. It is quick, everybody understands it, and the "won't" list prevents later arguments.

It is bad at ordering items **within** a group. Ten must-haves still need an order, and MoSCoW offers none. It also says nothing about time: a should-have whose value disappears in May and one that will be equally welcome in December sit in the same box. The next technique is about exactly that.
