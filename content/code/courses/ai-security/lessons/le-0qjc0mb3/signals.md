---
title: What to count, hour by hour
version: 1
---

Every control in this course produces a verdict: the schema of lesson 9 refuses a reply, the canary of
lesson 5 spots a system prompt in a reply, the gate of lesson 10 denies a call, a client reports a reply
in lesson 21. Each verdict protects one request. **Counted over time, the same verdicts tell you what
is happening to the whole assistant**, and that is what monitoring is: the defences you already have,
read as a stream instead of one at a time.

The counts that matter at Tarefa, and what a change in each one usually means:

| signal | from | a jump usually means |
|---|---|---|
| replies the schema refused | lesson 9 | a prompt or model change broke the format, as in lesson 20 |
| canary in a reply | lesson 5 | the system prompt reached a client; it should never happen |
| tool calls the gate denied | lesson 10 | an agent is proposing out of scope, often for one account |
| moderation blocks | lesson 6 | a change in what clients send, or in the model |
| spend per hour | lesson 18 | a loop, before the day's ceiling stops everybody |
| reports per thousand calls | lesson 21 | something clients notice that no check does |

Two days of hourly counts, **written by a rule rather than observed**, with three incidents planted in
the second day. Save the generator as `~/guard/tools/hourly.py`:

```python
# hourly.py: two days of the assistant's hourly counts, written by a rule.
#
#   guard hourly
#
# It writes data/hourly.jsonl, one line per hour from 2026-10-07 00:00 to
# 2026-10-08 23:00: calls, replies the schema refused (lesson 9), canary
# hits in replies (lesson 5), tool calls the gate denied (lesson 10) and
# client reports (lesson 21). The first day is ordinary, busy by day and
# quiet at night. The second has three incidents, planted by the course:
# a prompt change at 10:00 that triples refused replies, one canary in a
# reply at 14:00, and an account whose proposals the gate denies from 16:00
# to 17:00. Nothing here was observed.
import json
import os

TRAFFIC = [4, 2, 1, 1, 1, 3, 10, 30, 70, 110, 130, 140,
           120, 130, 140, 130, 120, 100, 80, 60, 40, 25, 12, 6]
rows = []
for day in ("2026-10-07", "2026-10-08"):
    for h, calls in enumerate(TRAFFIC):
        second = day == "2026-10-08"
        rejects = calls // 50 + (1 if h in (3, 4) else 0)
        if second and 10 <= h <= 12:
            rejects = calls // 12
        rows.append({"hour": "%s %02d:00" % (day, h), "calls": calls, "rejects": rejects,
                     "canary": 1 if second and h == 14 else 0,
                     "denies": 30 if second and h in (16, 17) else calls // 60,
                     "reports": 1 if h in (11, 15) else 0})
with open(os.path.expanduser("~/guard/data/hourly.jsonl"), "w", encoding="utf-8") as f:
    for r in rows:
        f.write(json.dumps(r) + "\n")
print("%d hours written to data/hourly.jsonl" % len(rows))
```

```
ana@lab:~/guard$ guard hourly
48 hours written to data/hourly.jsonl
ana@lab:~/guard$ head -3 data/hourly.jsonl
{"hour": "2026-10-07 00:00", "calls": 4, "rejects": 0, "canary": 0, "denies": 0, "reports": 0}
{"hour": "2026-10-07 01:00", "calls": 2, "rejects": 0, "canary": 0, "denies": 0, "reports": 0}
{"hour": "2026-10-07 02:00", "calls": 1, "rejects": 0, "canary": 0, "denies": 0, "reports": 0}
```

Forty-eight lines, one per hour. Tarefa's traffic has the shape most services have: 140 calls an hour
at the busiest and one at four in the morning. That shape matters more than anything else in the next
section, because **a rate computed over one call is a coin, not a measurement**.

## Count what the controls decide, not what the model says

None of these counts reads a reply's content. They count decisions code already made, so they are
cheap, they are the same whatever the model, and they hold no personal data. The call log of lesson
11 keeps the content, under its own retention; the monitoring keeps numbers, which can be kept longer
and shown to more people. A dashboard that displayed clients' messages to show what is going on would
be a second log with nobody's retention rules on it.
