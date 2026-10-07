---
title: Little's law with real numbers
version: 1
---

Lesson 3 introduced **Little's law** as the reason limiting work in progress shortens cycle time. With the Agenda team's March numbers it can be checked, and the check says something useful about the board.

```localised
average work in progress = average throughput × average cycle time
```

## The numbers

Over the four weeks from 2 to 29 March — **28 days** — the team finished **20 items**, a throughput of 20 / 28, or about **0.714 items a day**. The mean cycle time of those items was **7.75 days**. Little's law says the average number of items in progress over that period should have been about:

```localised
0.714 items a day × 7.75 days = 5.54 items
```

On the morning of 16 March, lesson 3's board showed **six** cards between the commitment point and Done: three in Developing, two in Review and one in Testing. Five and a half on average, six on one particular morning: the board and the law agree.

## What the agreement is for

The law holds for any stable system: one where work arrives and leaves at about the same rate over the period, and items are not abandoned halfway. When the numbers agree, as here, the team can use the law to reason about changes before making them:

- **To shorten cycle time without changing throughput, hold less in progress.** If the Agenda team worked with four items in progress instead of five or six, at the same throughput, the average cycle time would fall to about 4 / 0.714, or 5.6 days.
- **Starting more work does not raise throughput by itself.** It raises work in progress, and at the same throughput the law says cycle time rises with it.

When the numbers do **not** agree — the board shows twelve items in progress but the law predicts five — the usual cause is items that are on the board but not really being worked on: blocked, forgotten, waiting for a decision. The disagreement is a finding, and it points at the cards to look at.

## Its limits

Little's law is about **averages over a period**. It does not predict the cycle time of any single item, and it does not hold while the system is changing fast — in the first weeks after a reorganisation, or when a large batch of work arrives at once. The `delivery-metrics` course opens with it and works through those cases; here it is enough to know that the three numbers are linked, and that work in progress is the one a team controls directly.
