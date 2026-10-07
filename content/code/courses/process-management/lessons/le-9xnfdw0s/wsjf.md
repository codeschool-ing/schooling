---
title: Weighted shortest job first
version: 1
---

Cost of delay says how much waiting costs. It does not yet say what to do first, because items also differ in how long they take. Reinertsen's answer is **weighted shortest job first**, or WSJF: divide each item's cost of delay by its duration, and do the highest ratio first.

```localised
WSJF = cost of delay / job size
```

The logic is that of a queue. A short job with a high cost of delay should jump ahead of a long one, because while the short one is done the long one loses little, and the reverse would make the short one lose a lot. The ratio captures both at once.

## The SAFe version

Measuring cost of delay in money is hard, so SAFe, which made WSJF widely known, estimates it in **relative points** as the sum of three components, each on the modified Fibonacci scale of lesson 10:

- **user and business value** — how much users or the business want it;
- **time criticality** — how fast the value decays, the urgency profile of the previous section;
- **risk reduction and opportunity enablement** — how much it reduces risk or opens future options.

Job size is estimated on the same relative scale. The third component is the one that matters most to an architect, and the next-but-two section comes back to it.

## The Agenda team's four candidates

| feature | value | time | risk | cost of delay | size | WSJF |
|---|---|---|---|---|---|---|
| online booking | 13 | 8 | 3 | 24 | 13 | 1.85 |
| SMS reminders | 8 | 5 | 1 | 14 | 3 | 4.67 |
| database upgrade | 1 | 8 | 13 | 22 | 5 | 4.40 |
| reports for clinic owners | 8 | 2 | 2 | 12 | 8 | 1.50 |

The order is **SMS reminders, the database upgrade, online booking, then reports**. Online booking has the largest cost of delay of all, and it still comes third, because it is also the largest job: two smaller items deliver their value while it would still be in progress. The database upgrade, with almost no direct value to users, comes second, on the strength of its time criticality — the current version leaves support soon — and the risk it removes.

## In the workbook

With the components in columns B to E for rows 2 to 5, LibreOffice returned:

```localised
F2   =B2+C2+D2                                     24
G2   =ROUND(F2/E2,2)                               1.85
G3   =ROUND(F3/E3,2)                               4.67
=INDEX(A2:A5,MATCH(MAX(G2:G5),G2:G5,0))            SMS reminders
```

In Portuguese, `ROUND` is `ARRED`, `INDEX` is `ÍNDICE` and `MATCH` is `CORRESP`.

## Its limits

WSJF is a ratio of two estimates, so it inherits the uncertainty of both, and small changes in the inputs can swap neighbours. It is best used to separate the clearly-first from the clearly-last, with the middle settled by discussion. And because every component is relative, the numbers mean nothing outside the session that produced them, like the story points of lesson 10.
