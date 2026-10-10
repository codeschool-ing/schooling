---
title: Run the experiment yourself
version: 1
---

A real team gets one history. It changed its rules on one date, and it will never know what its September would have looked like without the change. The Billing team is a simulation, so you can **run the same team with the rules changed on a different day** and compare. `billing.py` takes the date as its only argument.

## The limit from the first day

```
ana@laptop:~/delivery$ python3 billing.py 2026-06-01
128 items merged, 27 not yet, 74 deploys
ana@laptop:~/delivery$ python3 compare.py 2026-06-01:2026-07-31 2026-09-01:2026-09-30 2026-06-01:2026-09-30
                        06-01..07-31  09-01..09-30  06-01..09-30
items finished                    66            34           128
work in progress                 7.4           5.9           6.7
finished per week                7.6           7.9           7.3
cycle time, median                 4             5             5
cycle time, 85th                   7             8             8
```

## The limit never

A date after the end of the history means the old rules for all four months.

```
ana@laptop:~/delivery$ python3 billing.py 2026-10-01
122 items merged, 30 not yet, 17 deploys
ana@laptop:~/delivery$ python3 compare.py 2026-06-01:2026-07-31 2026-09-01:2026-09-30 2026-06-01:2026-09-30
                        06-01..07-31  09-01..09-30  06-01..09-30
items finished                    52            39           122
work in progress                21.6          19.7          21.6
finished per week                6.0           9.1           7.0
cycle time, median                18            17            18
cycle time, 85th                  29            29            29
```

## Reading the three histories

Put the last column of each run side by side: the whole four months under each policy.

| policy | items finished | work in progress | median cycle time | 85th percentile |
|---|---|---|---|---|
| limit from 1 June | 128 | 6.7 | 5 days | 8 days |
| limit from 3 August (what happened) | 123 | 14.9 | 11 days | 26 days |
| no limit | 122 | 21.6 | 18 days | 29 days |

**The same people finished almost the same number of items under all three policies**: 122 to 128 in four months. What changed was how long each item took, by a factor of three to four. That is the lesson of the limit in one table, and you produced it on your own computer.

Two details keep the experiment honest.

- **September's throughput in the no-limit run is 9.1 a week**, the highest of any column. Not because the old rules are faster: the review queue happened to drain quickly that month. Over four months the same run finished the fewest. One month is noise; this is the previous section's warning, measured.
- **The runs are not the same items in a different order.** The random numbers are the same, but different rules consume them in a different order, so each run is its own plausible history. Compare their summaries, not individual items.

## Put it back

Every later lesson uses the real history, so run the program once more with no argument:

```
ana@laptop:~/delivery$ python3 billing.py
123 items merged, 19 not yet, 47 deploys
```

Try other dates too. A limit from 1 July, or from 1 September, shows how long the old queue takes to drain, which is the August lesson 1 found hard to read.
