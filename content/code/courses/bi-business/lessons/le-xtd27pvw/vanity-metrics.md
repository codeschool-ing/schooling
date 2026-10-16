---
title: Vanity metrics
version: 1
---

Some numbers are chosen because they look good, and the commonest way to look good is to be unable
to fall. **A cumulative total only grows**: registered customers, app downloads since launch, page
views since the site opened, products ever listed. Each new quarter is a record by construction, and
a chart of it climbs whatever the business does. A number like that is a **vanity metric**: it
flatters the people who report it and changes nobody's decision.

## The record that hides a decline

Varanda's online shop counts registered customers: everybody who has ever created an account. At the
end of each quarter of 2025, with the customers who actually bought something in the last twelve
months beside them:

| | A | B | C |
|---|---|---|---|
| 1 | Quarter | Registered | Active |
| 2 | Q1 | 188300 | 61200 |
| 3 | Q2 | 195900 | 60400 |
| 4 | Q3 | 203700 | 58900 |
| 5 | Q4 | 212400 | 57800 |

```localised
=ROUND((B5/B2-1)*100,1)      12.8
=ROUND((C5/C2-1)*100,1)      -5.6
```

Registered customers grew **12.8%** over the year, a new record every quarter, and that was the
number on marketing's slide. Active customers **fell 5.6%** over the same year: 3,400 fewer people
buying, while 24,100 more people had an account. The share of accounts that buy went from 32.5% to
27.2%:

```localised
=ROUND(C2/B2*100,1)      32.5
=ROUND(C5/B5*100,1)      27.2
```

**The registered total cannot show a customer leaving, because nobody deletes an account when they
stop buying.** It counts everybody who ever arrived and nobody who left, so it rises through a good
year and a bad one alike.

## The test

The test for a vanity metric is one question: **if this number doubled tomorrow, what would you do
differently?** For registered customers the honest answer is nothing, because a doubling could come
from a competition that hands out accounts and nobody buys anything. For active customers the answer
is concrete: the campaigns that reach lapsed customers, the products they used to buy, the reasons
they stopped. That is what makes a number **actionable**: a movement in it points to something to do.

A few common pairs, the vanity number first:

| looks good | says something |
|---|---|
| registered customers | active customers, bought in the last 12 months |
| app downloads | people who used the app in the last 30 days |
| page views | visits that ended in an order (conversion, lesson 10) |
| followers on social media | orders that came from social media |
| products listed | products that sold at least once this quarter |

Each right-hand number can fall, and that is why it is worth reading. It is also why the left-hand
ones are popular: a team judged on a number prefers one that cannot go down.

## Vanity is a use, not a kind of number

Registered customers is not a useless number. The person who plans the e-mail system's capacity
needs it, and for them it decides something. **What makes a number vanity is reporting it as
progress to people whose decisions it cannot inform.** The same total is a metric on one page and
vanity on another, which is the lesson 10 distinction seen from the other side: a KPI is chosen for
a decision, and a vanity metric is chosen for an audience.
