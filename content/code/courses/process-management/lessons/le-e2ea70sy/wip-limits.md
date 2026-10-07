---
title: Why limiting work in progress works
version: 1
---

A limit on work in progress looks like a restriction on how much a team can do. It is a restriction on how much a team can **start**, and the difference is the whole argument.

## Queues are where the time goes

Follow one item across a board with no limits. It spends a day being developed, then waits three days for somebody to review it, a day in review, then waits two days for a tester. Of seven days of cycle time, two were work and five were waiting. That proportion is common, and it is invisible from inside, because everybody on the team was busy the entire week — busy with other items.

Limiting work in progress attacks the waiting. If Review can hold only two items, a developer cannot drop a third in front of it and start something new; the queue in front of Review stays short, and items cross it faster.

## The law that connects the numbers

There is an arithmetic reason as well. For a stable system, **Little's law** says:

```localised
average work in progress = average throughput × average cycle time
```

Read it the other way round: average cycle time equals work in progress divided by throughput. If a team finishes five items a week, whatever it does, then holding ten items in progress means each one takes about two weeks, and holding five means about one. **Starting more work does not make anything finish sooner**; with the same throughput it only makes every item take longer. Lesson 13 comes back to the law with the Agenda team's numbers, and the `delivery-metrics` course spends its first lesson on it.

## Multitasking costs more than it seems

A developer with four items open does not work on four items at once; they switch between them, and every switch costs time spent remembering where they were. Gerald Weinberg's estimate, in *Quality Software Management* (1992), was that each extra project a person juggles takes a substantial share of their time in switching alone. The precise percentages are an estimate rather than a measurement, but the direction is what every developer recognises: **two things finished one after the other usually arrive before two things done in parallel**.

## Setting the limit

There is no correct number to start with. A common starting point is the number of people who work in a column, or a little more, and then to adjust: a limit that is never reached is not limiting anything, and a limit that leaves people idle for days is too tight. The point of setting one is the conversation it forces on the day it is hit — *why is Review full, and who can help?* — which is exactly the conversation a team without limits never has.
