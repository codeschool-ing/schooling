---
title: Four rules for one alert
version: 2
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
RELEASE = datetime(2026, 10, 1, 10)
before = [r["refused"] for r in week if r["at"] < RELEASE]
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
    "last 6 hours above 40%, 10 replies or more": lambda now: (lambda k, n: n >= 10 and k / n > 0.40)(*window(now, 6)),
    "yesterday above 30%, checked at midnight": lambda now: now.hour == 0 and (lambda k, n: n > 0 and k / n > 0.30)(*window(now, 24)),
    "last 24 hours surely above the baseline": lambda now: lower(*window(now, 24)) > BASELINE,
}
print(f"baseline: {sum(before)} refused of {len(before)} replies before the release, {BASELINE:.1%}")
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
ana@dev:~/obs$ python alerts.py
baseline: 31 refused of 134 replies before the release, 23.1%
last hour above 40%
    false alarms before the release  12   first after it: Thu 01 14:00, 4 h after   firing in 31 of the 86 hours after
last 6 hours above 40%, 10 replies or more
    false alarms before the release   0   first after it: Thu 01 11:00, 1 h after   firing in 21 of the 86 hours after
yesterday above 30%, checked at midnight
    false alarms before the release   0   first after it: Fri 02 00:00, 14 h after   firing in 3 of the 86 hours after
last 24 hours surely above the baseline
    false alarms before the release   0   first after it: Thu 01 15:00, 5 h after   firing in 55 of the 86 hours after
```

The release went out on Thursday at 10:00. Each rule is a different trade:

- **"The last hour above 40%"** catches the release four hours after it, and has already fired **12
  times** in the two and a half days before it. By day an hour holds two or three replies and at
  night none or one, so one refusal in two is enough. By Thursday nobody is reading it. Lesson 11's
  precision, measured on an alert: most of its firings are false.
- **"The last six hours above 40%, with 10 replies or more"** never fires falsely and catches the
  release first, an hour after it. Then it **goes quiet**: it fires in 21 of the 86 hours after,
  because every night drops below ten replies and by day the share hovers around 40%. An alert that
  resolves itself while the problem is still there tells the person who got it that the problem has
  gone.
- **"Yesterday above 30%, checked at midnight"** is safe and slow: fourteen hours after the release, at
  midnight, with the whole afternoon's customers already turned away.
- **"The last 24 hours surely above the baseline"** uses lesson 9's interval: it fires when even the low
  end of the 95% interval of the window's share is above the 23.1% of the days before. It catches the
  release in five hours, has **no** false alarm, and stays on for 55 of the 86 hours after.

The fourth rule is the one this team would keep, and the reason is in its definition. It has a minimum
sample built in: with few replies the interval is wide and its low end cannot clear the baseline, so
the nights cannot set it off, and nobody had to choose a number like ten. It compares with what this
assistant normally does, not with a number somebody picked, so it does not need retuning when a new
feature changes the usual share of refusals. And its window is a day because this shop has forty
replies a day: a busier assistant earns a shorter window by the same arithmetic, and a quieter one a
longer.
