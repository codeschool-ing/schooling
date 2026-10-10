---
title: The Billing team's history, on your computer
version: 1
---

The program below writes the Billing team's history into two files. **Save it as `billing.py` in your `delivery` folder**: copy it with the button on the block, paste it into any text editor, and save it under that name. Then run it.

```python
"""billing.py: the Billing team's history, June to September 2026.

The team is invented. This program simulates its board one working day at a
time and writes what the board and the pipeline would have recorded:

    items.csv     one row per work item, with the date it reached each column
    deploys.csv   one row per deployment, with the items it carried

The random numbers come from a fixed seed, so every computer that runs it
writes exactly the same files. On 3 August the team started limiting its work
in progress; LIMIT_FROM is that date, and lesson 4 asks you to move it.
"""
import csv
import random
import sys
from datetime import date, datetime, timedelta

START, END = date(2026, 6, 1), date(2026, 9, 30)
LIMIT_FROM = date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else date(2026, 8, 3)
DEVELOPERS = ["Caio", "Duda", "Ines", "Rafa", "Teo"]
rng = random.Random(43)


def workdays(first, last):
    day = first
    while day <= last:
        if day.weekday() < 5:
            yield day
        day += timedelta(days=1)


def new_item(number, created):
    effort = round(rng.lognormvariate(0.8, 0.6), 1)       # days of real work
    guess = effort * rng.lognormvariate(0, 0.5)            # what the team thought
    points = min([1, 2, 3, 5, 8], key=lambda p: abs(p - guess))
    kind = rng.choices(["feature", "bug", "chore"], [6, 3, 1])[0]
    return {"id": f"BIL-{number}", "type": kind, "points": points,
            "created": created, "started": "", "review": "", "merged": "",
            "left": effort}


items, backlog, waiting, parked, deploys = [], [], [], [], []
doing = {name: [] for name in DEVELOPERS}
numbers = iter(range(101, 1000))
for _ in range(25):                                        # the backlog on 1 June
    backlog.append(new_item(next(numbers), START - timedelta(days=rng.randint(3, 30))))

for day in workdays(START, END):
    limited = day >= LIMIT_FROM
    for name, item in parked[:]:                           # unblocked: back to its owner
        if item["until"] <= day:
            parked.remove((name, item))
            doing[name].append(item)
    for _ in range(rng.choice([0, 1, 1, 1, 2, 3])):        # requests that arrive
        backlog.append(new_item(next(numbers), day))
    reviewers = DEVELOPERS[:] if limited else ["Bia"] * rng.choice([0, 1, 1, 2, 2, 3])
    reviewed = []
    for name in reviewers:                                 # review first, oldest first
        if waiting and waiting[0]["review"] < day:
            reviewed.append(name)
            item = waiting.pop(0)
            item["merged"] = datetime(day.year, day.month, day.day,
                                      rng.randint(9, 17), rng.choice([0, 15, 30, 45]))
            items.append(item)
    for name in DEVELOPERS:
        mine = doing[name]
        while len(mine) < (1 if limited else 3) and backlog:
            item = backlog.pop(0)
            item["started"] = day
            mine.append(item)
        if not mine:
            continue
        item = rng.choice(mine)                            # what they work on today
        item["left"] -= (0.5 if name in reviewed else 1) * (1 if len(mine) == 1 else 0.8)
        if rng.random() < 0.02:                            # blocked, waiting on another team
            item["until"] = day + timedelta(days=rng.randint(5, 60))
            mine.remove(item)
            parked.append((name, item))
        elif item["left"] <= 0:
            item["review"] = day
            mine.remove(item)
            waiting.append(item)

    # The pipeline: every Thursday before the limit, every working day after it.
    ready = [i for i in items if i["merged"] and "deploy" not in i]
    if ready and (limited or day.weekday() == 3):
        hour = rng.randint(10, 17) if limited else 16
        at = datetime(day.year, day.month, day.day, hour, rng.choice([0, 20, 40]))
        failed = rng.random() < 1 - 0.96 ** len(ready)     # more changes, more risk
        deploy = {"id": f"D{len(deploys) + 1:03}", "at": at, "failed": int(failed),
                  "items": " ".join(i["id"] for i in ready), "restored": ""}
        if failed:                                         # and longer to undo
            minutes = rng.lognormvariate(3.3 + 0.25 * len(ready), 0.4)
            deploy["restored"] = at + timedelta(minutes=round(minutes))
        deploys.append(deploy)
        for i in ready:
            i["deploy"] = deploy["id"]

unfinished = backlog + waiting + [i for _, i in parked] + [i for m in doing.values() for i in m]
fields = ["id", "type", "points", "created", "started", "review", "merged"]
with open("items.csv", "w", newline="") as f:
    out = csv.DictWriter(f, fields, extrasaction="ignore")
    out.writeheader()
    out.writerows(sorted(items + unfinished, key=lambda i: int(i["id"][4:])))
with open("deploys.csv", "w", newline="") as f:
    out = csv.DictWriter(f, ["id", "at", "items", "failed", "restored"])
    out.writeheader()
    out.writerows(deploys)
print(f"{len(items)} items merged, {len(unfinished)} not yet, {len(deploys)} deploys")
```

You do not need to read it to use it, but it is short enough to read, and reading it once tells you what the history is made of.

**It is a simulation of the board, one working day at a time.** Each day, new requests arrive in the backlog, people review what is waiting for review, and each developer works on one of their open items. An item is finished when it has been worked on for as many days as it needed and then reviewed. Now and then an item is blocked, waiting on another team, and is set aside until it is free again. Every item gets a story-point estimate, drawn from what it really cost with plenty of error on top, because that is what estimates are; lesson 9 measures how much.

**The rules change on 3 August.** Before that date each developer keeps up to three items open and only Bia reviews, between her other duties. From that date each developer keeps one, and everybody reviews before starting anything new. The variable `LIMIT_FROM` holds the date, and the program accepts another one on the command line, which is how lesson 4 runs the same team with the rules changed on a different day.

**The pipeline changes on the same day.** Before the limit, whatever has merged is deployed every Thursday afternoon, in one batch. After it, whatever has merged is deployed every working day. A deployment carrying more changes is more likely to fail, and a failed one takes longer to undo. Lessons 5 to 7 measure what that did.

## Running it

```
ana@laptop:~/delivery$ python3 billing.py
118 items merged, 17 not yet, 47 deploys
ana@laptop:~/delivery$ head -5 items.csv
id,type,points,created,started,review,merged
BIL-101,bug,2,2026-05-28,2026-06-01,2026-06-02,2026-06-03 11:45:00
BIL-102,feature,1,2026-05-26,2026-06-01,2026-06-10,2026-06-11 13:00:00
BIL-103,feature,3,2026-05-02,2026-06-01,2026-07-02,2026-07-03 09:00:00
BIL-104,feature,3,2026-05-03,2026-06-01,2026-06-12,2026-06-15 16:30:00
ana@laptop:~/delivery$ head -3 deploys.csv
id,at,items,failed,restored
D001,2026-06-04 16:20:00,BIL-105 BIL-108 BIL-101 BIL-112,0,
D002,2026-06-11 16:40:00,BIL-119 BIL-114 BIL-116 BIL-102 BIL-117,0,
```

`head` prints the first lines of a file. It is not a Windows command; in PowerShell, `Get-Content items.csv -Head 5` does the same, and so does opening the file in any text editor or spreadsheet.

Your files are byte for byte the same as these, because the random numbers come from a fixed seed. If the first line says anything other than 118, 17 and 47, the program was changed while being copied, and the next section says how to find where.

## What the two files hold

`items.csv` has one row per work item, **135 of them**: the 118 merged by 30 September and the 17 that were not.

| column | what it records |
|---|---|
| `id` | the item's name on the board, from `BIL-101` |
| `type` | `feature`, `bug` or `chore` |
| `points` | the team's estimate, in story points |
| `created` | the day it entered the backlog |
| `started` | the day somebody started it; empty if nobody has |
| `review` | the day it was handed over for review |
| `merged` | the date and time its review finished and the change merged |

`deploys.csv` has one row per deployment: an `id`, the date and time it went out, the items it carried, whether it `failed` (1) or not (0), and, for a failed one, when service was `restored`.

**Those are exactly the columns a real board and a real pipeline give you**, under other names. Jira, Linear and GitHub Projects all record when an item changed column; every deployment tool records when it ran and how it ended. Each lesson that reads these files says which column it uses, so you can point the same program at an export of your own team's board.
