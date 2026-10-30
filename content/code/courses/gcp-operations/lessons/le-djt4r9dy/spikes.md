---
title: Finding the day the spend changed
version: 1
---

A spike is a day that costs more than **the usual**, and the usual is the thing to define carefully. The shop's daily
cost by service, for 45 days, made up by `days.py` so the file is the same for everybody, with something wrong from
9 October. Work in `~/gcp/bill` (`mkdir -p ~/gcp/bill && cd ~/gcp/bill`):

```python
# days.py: writes costs.csv, a made-up 45 days (or as many as asked) of the shop's daily cost by service
import csv
import datetime as dt
import random
import sys

rand = random.Random(25)
days = int(sys.argv[1]) if len(sys.argv) > 1 else 45
# service: USD on a weekday, USD on a weekend day
usual = {"Cloud Run": (11.5, 8.0), "Compute Engine": (5.2, 5.2), "Cloud Logging": (1.3, 1.0),
         "Cloud Build": (0.9, 0.2), "Cloud Storage": (0.6, 0.6)}
start = dt.date(2026, 9, 1)
with open("costs.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["date", "service", "usd"])
    for n in range(days):
        day = start + dt.timedelta(days=n)
        weekend = day.weekday() >= 5
        for service, (weekday_usd, weekend_usd) in usual.items():
            usd = (weekend_usd if weekend else weekday_usd) * rand.uniform(0.92, 1.08)
            if service == "Cloud Logging" and day >= dt.date(2026, 10, 9):
                usd += 40 * 0.50  # 40 GiB a day of debug logs, left on after a deployment
            w.writerow([day.isoformat(), service, f"{usd:.2f}"])
print(f"costs.csv: {days} days")
```

`spike.py` compares each day with the **median of the fourteen days before it**: a median ignores the one strange day
in the window, where an average would be pulled up by it. A day is a spike when it is 30% above the usual **and** more
than 5 USD above it, so that a cheap day doubling from 1 to 2 USD does not page anybody. For each spike it names the
service whose cost moved most against its own median:

```python
# spike.py: the days whose cost left the usual, and the service that moved
import collections
import csv
import statistics

daily = collections.defaultdict(dict)
for row in csv.DictReader(open("costs.csv")):
    daily[row["date"]][row["service"]] = float(row["usd"])
days = sorted(daily)

for i, day in enumerate(days):
    if i < 14:
        continue  # two weeks of history before judging anything
    before = days[i - 14:i]
    total = sum(daily[day].values())
    usual = statistics.median(sum(daily[d].values()) for d in before)
    if total > usual * 1.3 and total - usual > 5:
        moved = max(daily[day], key=lambda s: daily[day][s] - statistics.median(daily[d][s] for d in before))
        extra = daily[day][moved] - statistics.median(daily[d][moved] for d in before)
        print(f"{day}  {total:6.2f} USD, usual {usual:5.2f}  {moved} +{extra:.2f}")

october = [d for d in days if d.startswith("2026-10")]
so_far = sum(sum(daily[d].values()) for d in october)
print(f"October so far: {so_far:.2f} USD in {len(october)} days, "
      f"{so_far / len(october) * 31:.2f} at this rate for the month")
```

```
ana@laptop:~/gcp/bill$ python3 days.py
costs.csv: 45 days
ana@laptop:~/gcp/bill$ python3 spike.py
2026-10-09   39.50 USD, usual 18.86  Cloud Logging +20.04
2026-10-10   34.70 USD, usual 18.86  Cloud Logging +19.72
2026-10-11   34.39 USD, usual 19.05  Cloud Logging +19.75
2026-10-12   39.48 USD, usual 19.32  Cloud Logging +20.06
2026-10-13   39.11 USD, usual 19.37  Cloud Logging +19.91
2026-10-14   39.03 USD, usual 19.59  Cloud Logging +19.96
2026-10-15   39.26 USD, usual 19.84  Cloud Logging +20.03
October so far: 411.35 USD in 15 days, 850.12 at this rate for the month
```

**Every day since 9 October is about 20 USD above the usual, and all of it is Cloud Logging.** Twenty dollars a day at
0.50 USD per gibibyte, lesson 9's ingestion price, is forty gibibytes of logs a day that were not being written before.
That is not a billing question; it is an incident with a cause, here a debug level left on after a deployment, and it
goes through lesson 15 like any other: declared, mitigated by turning the level back down, reviewed.

The last line is the budget's forecast done by hand: at this pace October ends near 850 USD, past lesson 24's budget
of 700, which is the forecast rule firing on the 9th rather than on the 30th.

## The window that forgives

Read the `usual` column: it creeps from 18.86 to 19.84 USD. Each spike day enters the window, and after **seven** of
them, half of fourteen, the median is already moving towards the spike. Running the same program on sixty days shows
where that ends:

```
ana@laptop:~/gcp/bill$ python3 days.py 60
costs.csv: 60 days
ana@laptop:~/gcp/bill$ python3 spike.py | tail -3
2026-10-15   39.26 USD, usual 19.84  Cloud Logging +20.03
2026-10-16   38.98 USD, usual 27.19  Cloud Logging +10.10
October so far: 983.65 USD in 30 days, 1016.44 at this rate for the month
```

**The 16th is the last day reported.** From the 17th the debug logs are the usual, and nothing is reported at all. A
spike left alone becomes the new normal of any detector built on a recent baseline. **Detection buys a week, not a
fix**, and the week is for somebody to act.
