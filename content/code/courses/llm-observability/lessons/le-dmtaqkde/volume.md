---
title: Volume
version: 2
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
    print(f"{day}  {n:4}  {'#' * n}")
print()
for h in range(24):
    print(f"{h:02}h  {hours[h]:4}  {'#' * hours[h]}")
```

```
ana@dev:~/obs$ python volume.py
Mon 28    46  ##############################################
Tue 29    47  ###############################################
Wed 30    45  #############################################
Thu 01    55  #######################################################
Fri 02    48  ################################################
Sat 03    36  ####################################
Sun 04    34  ##################################

00h     0  
01h     2  ##
02h     2  ##
03h     2  ##
04h     4  ####
05h     4  ####
06h     7  #######
07h    13  #############
08h    20  ####################
09h    21  #####################
10h    19  ###################
11h    18  ##################
12h    17  #################
13h    20  ####################
14h    22  ######################
15h    20  ####################
16h    18  ##################
17h    15  ###############
18h    18  ##################
19h    20  ####################
20h    19  ###################
21h    19  ###################
22h     9  #########
23h     2  ##
```

Two shapes, both ordinary. **Weekdays are busier than weekends**, by about a quarter. **The day is
busy from eight in the morning to ten at night**, with a little more in mid-morning and
mid-afternoon, and almost nothing between midnight and six. The traffic was generated with that
shape on purpose, because it is the shape of nearly every service people use from work and from
home, and it is worth knowing for three reasons.

**Capacity and rate limits are set for the peak, not the average.** 22 requests in the busiest hour
of the week, spread over seven days, against none at midnight: the peak hour on a weekday runs at
several times the overnight rate. A provider's rate limit that is comfortable on average can be hit
every afternoon at three, and a computer that answers one question at a time, as Ollama does here,
queues every request that arrives while it is busy.

**A rate is only comparable within the same hours.** A refusal rate computed between midnight and
six is a rate over a handful of requests; the same rate between nine and five is over a hundred. A
dashboard that shows rates by hour without the volume beside them makes the small hours look
alarming every night.

**A drop in volume is a failure that sends no error.** If the shop's website stopped loading the
help widget, the assistant's error rate would be perfect: nobody asks, nothing fails. Volume against
the same hour last week is the alarm for that, and it is the only one that can see it. Lesson 16
says why it needs an alert of its own.