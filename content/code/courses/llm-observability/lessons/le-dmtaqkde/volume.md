---
title: Volume
version: 1
---

The first question about a system in production is the dullest and the one most often skipped: **how
much is it being used, and when?** Volume is the denominator of every other number in this lesson, and
a change in it is often the first sign of something else. `volume.py` draws the week as bars:

```python
"""volume.py: requests per day, and per hour of the day across the week, as bars."""
from collections import Counter

import costs

rows = costs.requests()
days = Counter(r["at"].strftime("%a %d") for r in rows)
hours = Counter(r["at"].hour for r in rows)
for day, n in days.items():
    print(f"{day}  {n:4}  {'#' * (n // 5)}")
print()
for h in range(24):
    print(f"{h:02}h  {hours[h]:4}  {'#' * (hours[h] // 3)}")
```

```
ana@lab:~/obs$ python volume.py
Mon 28   200  ########################################
Tue 29   210  ##########################################
Wed 30   207  #########################################
Thu 01   208  #########################################
Fri 02   224  ############################################
Sat 03   153  ##############################
Sun 04   143  ############################

00h    11  ###
01h    11  ###
02h    10  ###
03h     9  ###
04h     7  ##
05h    17  #####
06h    25  ########
07h    52  #################
08h    79  ##########################
09h    98  ################################
10h    94  ###############################
11h    82  ###########################
12h    72  ########################
13h    89  #############################
14h    96  ################################
15h    99  #################################
16h    72  ########################
17h    65  #####################
18h    73  ########################
19h    82  ###########################
20h    79  ##########################
21h    64  #####################
22h    37  ############
23h    22  #######
```

Two shapes, both ordinary. **Weekdays are busier than weekends**, by about a third. **The day has two
humps**, mid-morning and mid-afternoon, with a dip at lunch and a long evening tail, and almost nothing
between midnight and six. The traffic was generated with that shape on purpose, because it is the shape
of nearly every service people use from work and from home, and it is worth knowing for three reasons.

**Capacity and rate limits are set for the peak, not the average.** 99 requests in the busiest hour of
the week, spread over seven days, means the peak hour on a weekday runs at several times the overnight
rate. A provider's rate limit that is comfortable on average can be hit every afternoon at three.

**A rate is only comparable within the same hours.** A refusal rate computed between midnight and six
is a rate over a handful of requests; the same rate between nine and five is over hundreds. A dashboard
that shows rates by hour without the volume beside them makes the small hours look alarming every
night.

**A drop in volume is a failure that sends no error.** If the shop's website stopped loading the help
widget, the assistant's error rate would be perfect: nobody asks, nothing fails. Volume against the same
hour last week is the alarm for that, and it is the only one that can see it. Lesson 16 builds it.
