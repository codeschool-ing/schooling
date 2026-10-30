---
title: Fixed, sliding and session windows
version: 1
---

**A window is a rule that gives each element one or more intervals of event time, and a group is
computed once per key per interval.** Beam has three rules built in, and they answer three
different questions about the same orders:

| window | the rule | the question it answers |
|---|---|---|
| **fixed** | intervals of one length, end to end, aligned to the clock | how much in each five minutes |
| **sliding** | intervals of one length, starting every so often, so they overlap | how much in the last ten minutes, asked every five |
| **sessions** | an interval per key that grows while elements keep coming, and closes after a gap with none | how much did one customer order in one visit |

The first two are known in advance: the window 19:00 to 19:05 exists before any order does. **A
session is not**: it is made from the data, per key, by merging the small windows round each element
whenever they touch. That makes sessions the one kind whose boundaries move when late data
arrives: a late order that falls between two sessions of one customer merges them into one.

## One program, three windows

All three are run by the time each order was placed, and grouped rather than combined, so that
the output can count the orders as well as add them. Save it as `~/gcp/windows.py`:

`windows.py`:

```python
"""windows.py: the same orders cut three ways, all by the time each was placed.

    python3 windows.py fixed        five-minute windows, per neighbourhood
    python3 windows.py sliding      ten-minute windows every five, per neighbourhood
    python3 windows.py sessions     a customer's orders with gaps under five minutes
"""
import sys

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows, Sessions, SlidingWindows

from evening import ORDERS, clock, stamped

KIND = sys.argv[1]
WINDOW = {'fixed': FixedWindows(5 * 60),
          'sliding': SlidingWindows(10 * 60, 5 * 60),
          'sessions': Sessions(5 * 60)}[KIND]
KEY = 'customer' if KIND == 'sessions' else 'neighbourhood'


class Show(beam.DoFn):
    def process(self, group, window=beam.DoFn.WindowParam):
        key, cents = group
        print(f'{clock(window.start)}-{clock(window.end)}  {key:<10} '
              f'{len(cents)} order{"s" * (len(cents) != 1)}  {sum(cents) / 100:>7.2f}')


options = PipelineOptions([], runner='BundleBasedDirectRunner')
with beam.Pipeline(options=options) as p:
    (p
     | beam.Create(ORDERS)
     | beam.Map(stamped, KEY, 'placed')
     | beam.WindowInto(WINDOW)
     | beam.GroupByKey()
     | beam.ParDo(Show()))
```

```
ana@laptop:~/gcp$ python3 windows.py fixed | sort
19:00:00-19:05:00  Moema      3 orders    86.80
19:00:00-19:05:00  Pinheiros  2 orders   151.50
19:05:00-19:10:00  Moema      1 order    15.00
19:05:00-19:10:00  Pinheiros  2 orders    80.00
19:10:00-19:15:00  Moema      1 order    22.00
19:10:00-19:15:00  Pinheiros  1 order    56.00
```

**Fixed windows give every order exactly one home.** Ten orders, six groups, and the counts add to
ten. These are the totals by placing time from the previous section, now with a count beside them.

```
ana@laptop:~/gcp$ python3 windows.py sliding | sort
18:55:00-19:05:00  Moema      3 orders    86.80
18:55:00-19:05:00  Pinheiros  2 orders   151.50
19:00:00-19:10:00  Moema      4 orders   101.80
19:00:00-19:10:00  Pinheiros  4 orders   231.50
19:05:00-19:15:00  Moema      2 orders    37.00
19:05:00-19:15:00  Pinheiros  3 orders   136.00
19:10:00-19:20:00  Moema      1 order    22.00
19:10:00-19:20:00  Pinheiros  1 order    56.00
```

**Sliding windows give every order two homes**, because a ten-minute window starting every five
minutes overlaps the next by half. The window from 19:00 to 19:10 holds four orders of Moema and the
one from 19:05 to 19:15 holds two, and one of them, `o-505` at 19:06:00, is in both. The sums are
right for the question they answer, "the last ten minutes, as of each five-minute mark", and adding
them up across windows counts every order twice. The windows also start before the first order and
end after the last: **18:55 to 19:05 exists because 19:01:10 falls inside it**, which is why a
sliding window always reaches back by its length minus its period.

```
ana@laptop:~/gcp$ python3 windows.py sessions | sort
19:01:10-19:08:30  c-17       2 orders    55.80
19:02:05-19:07:05  c-02       1 order   128.00
19:04:20-19:09:20  c-05       1 order    23.50
19:04:50-19:09:50  c-44       1 order    31.00
19:06:00-19:14:10  c-31       2 orders    23.00
19:07:45-19:12:45  c-02       1 order    72.00
19:11:15-19:16:15  c-05       1 order    56.00
19:13:40-19:18:40  c-17       1 order    22.00
```

**Sessions are per customer here, with a gap of five minutes.** `c-17` ordered at 19:01:10 and
19:03:30, less than five minutes apart, so the two merged into one session from 19:01:10 to 19:08:30:
the last order's time plus the gap. Their third order, at 19:13:40, came after more than five quiet
minutes and opened a session of its own. `c-02` ordered at 19:02:05 and 19:07:45, 5 minutes 40
seconds apart, and got two sessions; a gap of six minutes would have made it one. **The gap is the
whole definition**, and choosing it is choosing what a visit is. For Quitanda, a customer who
orders again within five minutes has usually forgotten something, and counting the two as one
basket is what the warehouse wants.

## Choosing one

| if the question is | the window |
|---|---|
| a report per hour, per day, per five minutes | fixed |
| a moving figure, refreshed often: orders in the last hour, every minute | sliding |
| behaviour of one user or one device, with no natural clock | sessions |
| the whole stream, with results whenever they are wanted | the global window with a trigger, the fifth section |

**A sliding window costs its overlap.** Every element is placed in length ÷ period windows: two
here, sixty for "the last hour, every minute". Each copy is state the runner keeps until the window
closes, and on Dataflow that state is part of what Streaming Engine is billed for.
