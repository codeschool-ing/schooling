---
title: Measuring alert fatigue
version: 1
---

**Alert fatigue** is what happens to people paged for things that need nothing from them: they learn,
correctly, that most pages can be ignored, and then they ignore the one that could not. Nobody decides
to stop reading pages. It happens by the fortieth page about a database at 80% CPU that nobody needed to
know about, and it shows in the numbers long before it shows in an incident.

The numbers are the pages themselves. A paging service exports them; the shop's month is made up here,
by a program, so it can be the same file for everybody. It writes one row per page: when, which alarm,
and whether the person paged **acted on it**, meaning did anything at all beyond acknowledging and going
back to sleep.

```python
# month.py: writes pages.csv, a made-up month of pages for the shop's API
import csv
import datetime as dt
import random

# alarm: (pages a day, share of pages somebody acted on, hours it tends to fire)
alarms = {
    "api-errors": (0.5, 0.8, range(24)),
    "api-latency": (0.6, 0.5, range(24)),
    "db-cpu": (1.5, 0.05, range(24)),
    "queue-depth": (0.8, 0.1, range(8, 20)),
    "disk-80": (1.0, 0.0, [3]),  # the nightly backup fills the disk for an hour
}
rand = random.Random(14)
start = dt.datetime(2026, 9, 14, tzinfo=dt.timezone(dt.timedelta(hours=-3)))
rows = []
for day in range(28):
    for name, (per_day, acted, hours) in alarms.items():
        for _ in range(int(per_day) + (rand.random() < per_day % 1)):
            at = start + dt.timedelta(days=day, hours=rand.choice(hours), minutes=rand.randrange(60))
            rows.append((at.isoformat(), name, "yes" if rand.random() < acted else "no"))
with open("pages.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["time", "alarm", "acted"])
    w.writerows(sorted(rows))
print(len(rows), "pages written")
```

The table at the top is the month's shape, and it is a shape real rotations have: two alarms on
symptoms customers feel, and three on causes that might matter, one of which fires every night because
a backup fills the disk for an hour.

```
ana@laptop:~/aws/oncall$ python3 month.py
121 pages written
ana@laptop:~/aws/oncall$ head -4 pages.csv
time,alarm,acted
2026-09-14T03:55:00-03:00,disk-80,no
2026-09-14T08:18:00-03:00,db-cpu,no
2026-09-14T14:25:00-03:00,queue-depth,no
```

Then a second program counts what the month cost:

```python
# fatigue.py: what a month of pages cost, alarm by alarm
# python3 fatigue.py [ALARM...] counts only the alarms named, if any
import collections
import csv
import datetime as dt
import sys

pages = collections.Counter()
acted = collections.Counter()
night = collections.Counter()
keep = set(sys.argv[1:])
for row in csv.DictReader(open("pages.csv")):
    if keep and row["alarm"] not in keep:
        continue
    hour = dt.datetime.fromisoformat(row["time"]).hour
    pages[row["alarm"]] += 1
    acted[row["alarm"]] += row["acted"] == "yes"
    night[row["alarm"]] += hour >= 22 or hour < 7

total = sum(pages.values())
print(f"{'alarm':<12} {'pages':>5} {'acted':>5} {'night':>5}")
for name, n in pages.most_common():
    print(f"{name:<12} {n:>5} {acted[name]:>5} {night[name]:>5}")
print(f"{'total':<12} {total:>5} {sum(acted.values()):>5} {sum(night.values()):>5}")
print(f"acted on: {sum(acted.values()) / total:.0%}, pages a week: {total / 4:.1f}")
```

```
ana@laptop:~/aws/oncall$ python3 fatigue.py
alarm        pages acted night
db-cpu          41     3    19
disk-80         28     0    28
queue-depth     22     2     0
api-errors      15    11     6
api-latency     15     7     4
total          121    23    57
acted on: 19%, pages a week: 30.2
```

Read it in three numbers. **121 pages in four weeks** is thirty a week, four a day, when the SRE book's
ceiling was two incidents in a twelve-hour shift. **57 at night**, nearly half, and `disk-80` sent all 28
of its pages between 22:00 and 07:00. And the one that matters most: **somebody acted on 19%**. Four
pages in five asked for nothing, and the person on call learnt that lesson thirty times a week.

The table says where it comes from. `db-cpu` is the noisiest alarm and the least useful one, 3 actions
in 41 pages. `api-errors` is the opposite: 11 of 15. A single measure orders them, **the share of an
alarm's pages somebody acted on**, and it is the number to look at in the weekly handoff, alarm by alarm,
not only in total.

## The same month, paging on symptoms only

Lesson 10's rule was to page on symptoms and record causes. The program takes the alarms to keep, so the
rule can be tried on last month before it is applied to next month:

```
ana@laptop:~/aws/oncall$ python3 fatigue.py api-errors api-latency
alarm        pages acted night
api-errors      15    11     6
api-latency     15     7     4
total           30    18    10
acted on: 60%, pages a week: 7.5
```

**30 pages instead of 121**, 10 at night instead of 57, and 60% of them acted on. The 5 actions on
causes are the question to ask before moving anything: did any of them have to happen at night, or would
`api-errors` have paged anyway if the cause had reached customers? When the answer is the second, the
cause alarm becomes a ticket, seen in the morning, and that move is the next section.
