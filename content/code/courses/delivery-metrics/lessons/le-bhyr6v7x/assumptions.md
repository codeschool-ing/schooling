---
title: Change the window and watch the forecast move
version: 1
---

Every Monte Carlo forecast rests on one bet: **the days it learns from look like the days to come**. The programs take the window as two optional dates, so you can test the bet directly. Here is the same pair of questions, learned from June and July, under the old rules, instead of from late August and September.

```
ana@laptop:~/delivery$ python3 howmany.py 31 2026-06-01 2026-07-31
learning from 61 days, 52 items; 10000 runs of 31 days
    8-11                                  0.1%
   12-15  #                               1.5%
   16-19  ########                        7.6%
   20-23  #####################          21.1%
   24-27  #############################  29.3%
   28-31  ########################       23.5%
   32-35  ############                   12.2%
   36-39  ####                            3.7%
   40-43  #                               0.9%
   44-47                                  0.1%
   48-51                                  0.0%
50% of runs finished at least 26 items
70% of runs finished at least 23 items
85% of runs finished at least 21 items
95% of runs finished at least 18 items
ana@laptop:~/delivery$ python3 when.py 30 2026-06-01 2026-07-31
30 items from 2026-10-01; 10000 runs
50% of runs finished by Wed 04 Nov
70% of runs finished by Sun 08 Nov
85% of runs finished by Thu 12 Nov
95% of runs finished by Mon 16 Nov
```

The 85% forecast for October drops from 29 items to **21**, and the date for thirty items moves from the end of October to **12 November**, nearly two weeks later. Same team, same people, same program. The only difference is which history it believed.

## Choosing the window

Neither window is wrong in itself; the question is which one describes the team that will do the work. Since 3 August the Billing team has worked under different rules, and June and July describe a team that no longer exists. Lesson 1 made the same point about averages, and it applies with more force here, because a forecast is a promise somebody will plan around.

Three rules for the window:

- **One policy only.** Never span a change of rules, and leave out the weeks right after one, while the old system drains.
- **Long enough to include bad days.** Thirty to sixty days is common. Two good weeks make an optimistic forecast.
- **Recent.** If the team, the product or the kind of work has changed, the history has expired, whatever its length.

## When the other assumptions fail

**The days are not independent** when bad days cluster: a week of incidents, a holiday period, a release crunch. The simulation then underestimates how bad a run of days can be. If your history has visible clusters, widen the confidence you quote, or forecast with the 95th percentile instead of the 85th.

**The items are not comparable** when the work ahead is a different kind from the work behind: the first integration with a new partner, a migration. Lesson 9's advice holds: there is no history for genuinely new work, and a reference class or an estimate has to fill the gap.

**The scope is not fixed**, ever. Lesson 11 adds it.

## Re-forecast, every week

A forecast is not made once. Every week brings new history and fewer items left, and re-running the two commands takes seconds. **A forecast that is updated weekly drifts towards the truth**, and the drift itself is information: if the 85% date keeps sliding later, something in the system has changed, and the team knows weeks before a deadline is missed rather than on the day.
