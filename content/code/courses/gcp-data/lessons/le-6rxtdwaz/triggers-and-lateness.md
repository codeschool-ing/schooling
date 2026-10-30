---
title: Triggers, allowed lateness and accumulation
version: 1
---

**A window says which elements belong together; a trigger says when to emit what the window holds,
and it may say so more than once.** Each emission is a **pane**. The default trigger fires one pane,
when the watermark passes the end of the window, and that is all the previous section saw. Three
settings change it, and between them they decide whether a late order is counted, when a result
first appears, and what a consumer has to do with a second result for the same window:

| setting | in `late.py` | what it decides |
|---|---|---|
| **allowed lateness** | `--lateness 300` | how long after the watermark passes a window its state is kept, so that late data still counts |
| **a late trigger** | `AfterCount(1)` | when a late arrival is emitted: here, a new pane for each one |
| **an early trigger** | `--early`, `AfterProcessingTime(60)` | a pane before the watermark arrives: here, a minute of processing time after the first element |
| **accumulation mode** | `--mode` | whether each pane carries everything so far, or only what is new since the last |

## Five minutes of allowed lateness

```
ana@laptop:~/gcp$ python3 late.py --lateness 300
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 0
19:00:00-19:05:00  Pinheiros   151.50  LATE     pane 1
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 0
19:05:00-19:10:00  Pinheiros    80.00  LATE     pane 1
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 0
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 0
```

**Two of the three late orders are back, each as a `LATE` pane.** Pinheiros's 19:00 window fired on
time with 128.00, as before, and then again with 151.50 when `o-504` arrived, which is the right
total. Its 19:05 window did the same for `o-510`: 72.00 on time, 80.00 late. The pane index counts
the emissions of one window and key, 0 and then 1.

**`o-507` is still missing.** Allowed lateness is measured against the watermark, not against the
clock on the wall: the 19:00 window ends at 19:05, so with 300 seconds allowed it is kept until the
watermark reaches 19:10, and then it is gone for good. `o-508` arrived at 19:11:16 and moved the
watermark to 19:10:16. `o-507` arrived at 19:12:30, a minute and fourteen seconds after its
window's state had been thrown away, and was dropped, as silently as before. **Allowed lateness is a
bound you choose on how much state the pipeline keeps**, and something always falls outside it: here,
an order that spent 7 minutes and 40 seconds in transit against an allowance of 5 plus the
watermark's one.

## Early panes, accumulating

```
ana@laptop:~/gcp$ python3 late.py --lateness 300 --early
19:00:00-19:05:00  Moema        45.90  EARLY    pane 0
19:00:00-19:05:00  Pinheiros   128.00  EARLY    pane 0
19:00:00-19:05:00  Moema        55.80  EARLY    pane 1
19:00:00-19:05:00  Moema        55.80  ON_TIME  pane 2
19:00:00-19:05:00  Pinheiros   128.00  ON_TIME  pane 1
19:05:00-19:10:00  Moema        15.00  EARLY    pane 0
19:00:00-19:05:00  Pinheiros   151.50  LATE     pane 2
19:05:00-19:10:00  Pinheiros    72.00  EARLY    pane 0
19:05:00-19:10:00  Moema        15.00  ON_TIME  pane 1
19:05:00-19:10:00  Pinheiros    72.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros    56.00  EARLY    pane 0
19:05:00-19:10:00  Pinheiros    80.00  LATE     pane 2
19:10:00-19:15:00  Moema        22.00  EARLY    pane 0
19:10:00-19:15:00  Moema        22.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros    56.00  ON_TIME  pane 1
```

**Now each window speaks before it is complete.** Moema's 19:00 window first said 45.90, a minute of
processing time after `o-501` arrived, when it held that order alone. It said 55.80 once `o-503` had
been in for a minute, and then 55.80 again on time, because nothing new had come. That is the trade an
early trigger makes: a screen in the warehouse sees a number within a minute instead of at 19:06,
and the number it sees first is wrong in the direction of too little.

**In accumulating mode every pane is the whole window so far**, so the last pane for a window and key
is the answer, and a consumer that keeps only the latest pane per window is always right. That is
what lets the BigQuery table or the screen downstream be written by replacing a row, keyed by the
window and the neighbourhood.

## Early panes, discarding

```
ana@laptop:~/gcp$ python3 late.py --lateness 300 --early --mode discarding
19:00:00-19:05:00  Moema        45.90  EARLY    pane 0
19:00:00-19:05:00  Pinheiros   128.00  EARLY    pane 0
19:00:00-19:05:00  Moema         9.90  EARLY    pane 1
19:00:00-19:05:00  Moema         0.00  ON_TIME  pane 2
19:00:00-19:05:00  Pinheiros     0.00  ON_TIME  pane 1
19:05:00-19:10:00  Moema        15.00  EARLY    pane 0
19:00:00-19:05:00  Pinheiros    23.50  LATE     pane 2
19:05:00-19:10:00  Pinheiros    72.00  EARLY    pane 0
19:05:00-19:10:00  Moema         0.00  ON_TIME  pane 1
19:05:00-19:10:00  Pinheiros     0.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros    56.00  EARLY    pane 0
19:05:00-19:10:00  Pinheiros     8.00  LATE     pane 2
19:10:00-19:15:00  Moema        22.00  EARLY    pane 0
19:10:00-19:15:00  Moema         0.00  ON_TIME  pane 1
19:10:00-19:15:00  Pinheiros     0.00  ON_TIME  pane 1
```

**In discarding mode each pane is only what arrived since the previous one.** Moema's 19:00 window
said 45.90, then 9.90, which is `o-503` alone, then 0.00 on time: the on-time pane fired although
nothing had arrived since the last early one, and a sum of nothing is zero. Pinheiros's late pane
for 19:00 is 23.50, `o-504` alone, where accumulating mode said 151.50. **Here the answer is the sum of
all the panes**, and a consumer has to add them: replacing a row with each pane, as the accumulating
consumer did, would leave Pinheiros's first window at 23.50.

So the mode is not a matter of taste. It is a contract with whatever reads the output:

- **accumulating** suits a sink that can overwrite by key, a row per window in a table or a cache
  entry; a duplicate delivery of a pane does no harm, which is lesson 20's idempotency again;
- **discarding** suits a sink that adds, such as a counter or a stream another pipeline sums, and
  costs less to emit; but a pane delivered twice is counted twice.

## The second way out of lesson 21's error

Lesson 21 refused to group an unbounded stream in the global window with the default trigger, and
named two ways out. Windows were the first. The second is to keep the global window and give it a
trigger that fires on processing time, which turns the pipeline into running totals of the whole
stream, refreshed every minute:

```python
beam.WindowInto(GlobalWindows(),
                trigger=trigger.Repeatedly(trigger.AfterProcessingTime(60)),
                accumulation_mode=trigger.AccumulationMode.ACCUMULATING)
```

**That line is shown and not run in this lesson.** It suits a total since the start, such as orders
today when the pipeline is restarted every midnight. It does not suit a question about an interval,
because the global window has no interval: a late order is never late, since the window never ends,
and nothing ever says a total is final.
