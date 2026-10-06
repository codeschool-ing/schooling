---
title: Four rules for one alert
version: 1
---

An alert is a rule evaluated on a schedule: every hour, say, the alerting system computes a number
over a recent window and compares it with a threshold. `alerts.py` evaluates four rules for "refusals
are up" every hour of the replayed week, and counts what each would have done:

```python
"""alerts.py: four rules for "refusals are up", each evaluated every hour of the week as an alerting system would."""
import math
from datetime import datetime, timedelta

import replies

week = replies.week()
RELEASE = datetime(2026, 10, 2, 10)
before = [r["refused"] for r in week if r["at"] < datetime(2026, 10, 1)]
BASELINE = sum(before) / len(before)


def window(now, hours):
    """(refused, replies) in the HOURS before NOW."""
    rs = [r["refused"] for r in week if now - timedelta(hours=hours) <= r["at"] < now]
    return sum(rs), len(rs)


def lower(k, n, z=1.96):
    """The low end of the 95% Wilson interval of k in n, lesson 9's."""
    if n == 0:
        return 0.0
    p = k / n
    return ((p + z * z / (2 * n)) - z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))) / (1 + z * z / n)


RULES = {
    "last hour above 40%": lambda now: (lambda k, n: n > 0 and k / n > 0.40)(*window(now, 1)),
    "last 3 hours above 40%, 30 replies or more": lambda now: (lambda k, n: n >= 30 and k / n > 0.40)(*window(now, 3)),
    "yesterday above 30%, checked at midnight": lambda now: now.hour == 0 and (lambda k, n: n > 0 and k / n > 0.30)(*window(now, 24)),
    "last 6 hours surely above the baseline": lambda now: lower(*window(now, 6)) > BASELINE,
}
print(f"baseline: {sum(before)} refused of {len(before)} replies before 1 October, {BASELINE:.1%}")
hours = [datetime(2026, 9, 29) + timedelta(hours=h) for h in range(24 * 6 + 1)]
for name, rule in RULES.items():
    fired = [h for h in hours if rule(h)]
    early = [h for h in fired if h <= RELEASE]
    late = [h for h in fired if h > RELEASE]
    first = f"{late[0]:%a %d %H:%M}, {(late[0] - RELEASE).total_seconds() / 3600:.0f} h after" if late else "never"
    print(f"{name}\n    false alarms before the release {len(early):3}   first after it: {first}"
          f"   firing in {len(late)} of the {sum(h > RELEASE for h in hours)} hours after")
```

```
ana@lab:~/obs$ python alerts.py
baseline: 136 refused of 551 replies before 1 October, 24.7%
last hour above 40%
    false alarms before the release  19   first after it: Fri 02 13:00, 3 h after   firing in 25 of the 62 hours after
last 3 hours above 40%, 30 replies or more
    false alarms before the release   0   first after it: Fri 02 14:00, 4 h after   firing in 6 of the 62 hours after
yesterday above 30%, checked at midnight
    false alarms before the release   0   first after it: Sat 03 00:00, 14 h after   firing in 3 of the 62 hours after
last 6 hours surely above the baseline
    false alarms before the release   1   first after it: Fri 02 14:00, 4 h after   firing in 28 of the 62 hours after
```

The release went out on Friday at 10:00. Each rule is a different trade:

- **"The last hour above 40%"** catches the release three hours after it, and has already fired **19
  times** in the three days before it, almost all at night, when an hour holds one or two replies. By
  Friday nobody is reading it. Lesson 11's precision, measured on an alert: most of its firings are
  false.
- **"The last three hours above 40%, with 30 replies or more"** never fires falsely, catches the release
  in four hours, and then **goes quiet**: it fires in 6 of the 62 hours after, because the share hovers
  around 40% and every night drops below the minimum. An alert that resolves itself while the problem is
  still there tells the person who got it that the problem has gone.
- **"Yesterday above 30%, checked at midnight"** is safe and slow: fourteen hours after the release, at
  midnight, with the whole evening's customers already turned away.
- **"The last six hours surely above the baseline"** uses lesson 9's interval: it fires when even the low
  end of the 95% interval of the window's share is above the 24.7% of the days before. It catches the
  release in four hours, stays on for 28 of the 62 hours after, and has **one** false alarm in three days.

The fourth rule is the one this team would keep, and the reason is in its definition. It has a minimum
sample built in: with few replies the interval is wide and its low end cannot clear the baseline, so
the nights cannot set it off. And it compares with what this assistant normally does, not with a
number somebody picked, so it does not need retuning when a new feature changes the usual share of
refusals.
