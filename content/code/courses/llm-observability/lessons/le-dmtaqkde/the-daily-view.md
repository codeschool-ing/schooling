---
title: One line a day
version: 2
---

Each signal so far was its own script. Day to day, what somebody actually reads is one table with all
of them, a line per day, and the release beside each. `daily.py` is that table for the help and order
features:

```python
"""daily.py: one line a day of the numbers that say how the assistant is doing."""
import json
from collections import Counter, defaultdict

import costs

rows = [r for r in costs.requests() if r["feature"] != "summary"]
day = {r["trace"]: r["at"].strftime("%a %d") for r in rows}
n, refused, releases = Counter(), Counter(), defaultdict(set)
for r in rows:
    d = day[r["trace"]]
    n[d] += 1
    refused[d] += r["outcome"] == "refused"
    releases[d].add(r["release"])
fb = defaultdict(Counter)
for f in map(json.loads, open("feedback.jsonl")):
    if f["trace"] in day:
        fb[day[f["trace"]]][f["kind"] + ("-" + f["value"] if f["kind"] == "thumbs" else "")] += 1
print(f"{'day':7} {'requests':>8} {'refused':>8} {'down/rated':>11} {'rephrased':>9} {'person':>7}  release")
for d in n:
    c = fb[d]
    rated = c["thumbs-up"] + c["thumbs-down"]
    print(f"{d:7} {n[d]:8} {refused[d] / n[d]:8.0%} {c['thumbs-down']:5}/{rated:<5} {c['rephrase'] / n[d]:9.0%} "
          f"{c['escalate'] / n[d]:7.0%}  {' '.join(sorted(releases[d]))}")
```

```
ana@dev:~/obs$ python daily.py
day     requests  refused  down/rated rephrased  person  release
Mon 28        39      28%     3/10           8%      0%  2026.09.4
Tue 29        42      19%     1/13           7%      0%  2026.09.4
Wed 30        42      19%     1/9            5%      0%  2026.09.4
Thu 01        49      51%     1/6           20%      2%  2026.09.4 2026.10.1
Fri 02        39      33%     1/11           5%      3%  2026.10.1
Sat 03        32      44%     2/5           16%      3%  2026.10.1
Sun 04        32      28%     0/4            6%      3%  2026.10.1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three lines over the seven days of the week, in percent of requests. Refused: 28, 19 and 19 from Monday to Wednesday, then 51 on Thursday, 33 on Friday, 44 on Saturday and 28 on Sunday. Rephrased: 8, 7, 5, then 20, 5, 16 and 6. Asked for a person: 0, 0, 0, then 2, 3, 3 and 3. A dashed line on Thursday marks the release of 1 October at 10:00.\"><path d=\"M62 220 L568 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M56 190 L62 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M56 160 L62 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M56 130 L62 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M56 100 L62 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M56 70 L62 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50</text><text x=\"70.0\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mon 28</text><text x=\"151.667\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tue 29</text><text x=\"233.334\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wed 30</text><text x=\"315.001\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Thu 01</text><text x=\"396.668\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Fri 02</text><text x=\"478.335\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sat 03</text><text x=\"560.002\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M308.2 40 L308.2 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"304.2\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">release 2026.10.1</text><path d=\"M70.0 136 L151.667 163 L233.334 163 L315.001 67 L396.668 121 L478.335 88 L560.002 136\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"163\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"233.334\" cy=\"163\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"315.001\" cy=\"67\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"396.668\" cy=\"121\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"478.335\" cy=\"88\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"560.002\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"576\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><path d=\"M70.0 196 L151.667 199 L233.334 205 L315.001 160 L396.668 205 L478.335 172 L560.002 202\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"196\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"199\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"233.334\" cy=\"205\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"315.001\" cy=\"160\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"396.668\" cy=\"205\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"478.335\" cy=\"172\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"560.002\" cy=\"202\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"576\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">rephrased</text><path d=\"M70.0 220 L151.667 220 L233.334 220 L315.001 214 L396.668 211 L478.335 211 L560.002 211\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70.0\" cy=\"220\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"220\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"233.334\" cy=\"220\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"315.001\" cy=\"214\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"396.668\" cy=\"211\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"478.335\" cy=\"211\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"560.002\" cy=\"211\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"576\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">asked for a person</text><text x=\"315\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">% of requests, help and order</text></svg>", "caption": "Three signals nobody had to ask a customer for, moving together on the day of the release."}
```

Read it as somebody would on Monday 5 October. Monday to Wednesday, the refusal rate sits between
19% and 28%, rephrasing between 5% and 8%, and nobody asked for a person. **On Thursday all three
jump**: 51% refused, 20% rephrased, and the week's first request for a person. Thursday is the only
day with two releases in it. From then on, somebody asks for a person every day, and the refusal
rate stays above Tuesday's and Wednesday's every day. The thumbs say almost nothing, because there
are between four and thirteen of them a day.

## What the week says, put together

Lesson 3 found that the cost per request fell by half over the week, and most of that after
Thursday's release. This lesson finds that from the same moment, customers were refused more, asked
again more, and began to give up on the assistant and ask for a person. **The release made the
assistant cheaper by making it worse**, and only a view with both in it shows that as one event
rather than two pieces of news, one good and one bad.

The decision follows: put the floor back, and work on the order questions some other way (the previous
sections pointed at the search). Lesson 14 is where a change like that gets tested against the
evaluation set before it ships, so that the next release that raises a floor is caught on a pull
request rather than a day later, in production.

## What this view still cannot see

Every number in the table is about **behaviour**: what was refused, what people did next. Not one of
them says whether the replies that were not refused were right. A confident wrong answer, which the
customer believes and acts on, gets no thumb, no rephrasing and no request for a person. It is the
most harmful failure an assistant like this has, and it is invisible to everything in lessons 1 to 5.
Lessons 8 to 13 build the instruments that see it.
