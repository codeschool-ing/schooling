---
title: One line a day
version: 1
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
ana@lab:~/obs$ python daily.py
day     requests  refused  down/rated rephrased  person  release
Mon 28       178      26%     6/25          13%      4%  2026.09.4
Tue 29       187      27%    13/32          17%      5%  2026.09.4
Wed 30       186      21%    14/34          17%      5%  2026.09.4
Thu 01       191      22%     8/28          14%      3%  2026.09.4
Fri 02       208      32%    16/31          23%      9%  2026.09.4 2026.10.1
Sat 03       141      40%    13/21          23%     11%  2026.10.1
Sun 04       130      36%     9/20          19%      7%  2026.10.1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three lines over the seven days of the week, in percent of requests. Refused: 26, 27, 21, 22, then 32 on Friday, 40 on Saturday, 36 on Sunday. Rephrased: 13, 17, 17, 14, then 23, 23 and 19. Asked for a person: 4, 5, 5, 3, then 9, 11 and 7. A dashed line on Friday marks the release of 2 October at 10:00.\"><path d=\"M62 220 L568 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M56 180 L62 180\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M56 140 L62 140\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M56 100 L62 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><path d=\"M56 60 L62 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"52\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><text x=\"70\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mon 28</text><text x=\"151.667\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Tue 29</text><text x=\"233.333\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Wed 30</text><text x=\"315\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Thu 01</text><text x=\"396.667\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Fri 02</text><text x=\"478.333\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sat 03</text><text x=\"560\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M384.667 40 L384.667 220\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"380.667\" y=\"34\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">release 2026.10.1</text><path d=\"M70 116 L151.667 112 L233.333 136 L315 132 L396.667 92 L478.333 60 L560 76\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70\" cy=\"116\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"112\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"233.333\" cy=\"136\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"315\" cy=\"132\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"396.667\" cy=\"92\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"478.333\" cy=\"60\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"560\" cy=\"76\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"576\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><path d=\"M70 168 L151.667 152 L233.333 152 L315 164 L396.667 128 L478.333 128 L560 144\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70\" cy=\"168\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"152\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"233.333\" cy=\"152\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"315\" cy=\"164\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"396.667\" cy=\"128\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"478.333\" cy=\"128\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"560\" cy=\"144\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"576\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">rephrased</text><path d=\"M70 204 L151.667 200 L233.333 200 L315 208 L396.667 184 L478.333 176 L560 192\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"70\" cy=\"204\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"151.667\" cy=\"200\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"233.333\" cy=\"200\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"315\" cy=\"208\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"396.667\" cy=\"184\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"478.333\" cy=\"176\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><circle cx=\"560\" cy=\"192\" r=\"3.5\" fill=\"var(--paper)\" stroke=\"none\"></circle><text x=\"576\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">asked for a person</text><text x=\"315\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">% of requests, help and order</text></svg>", "caption": "Three signals nobody had to ask a customer for, moving together on the day of the release."}
```

Read it as somebody would on Monday 5 October. Monday to Thursday, the refusal rate sits between 21%
and 27%, rephrasing between 13% and 17%, requests for a person between 3% and 5%. **On Friday all
three jump**, and on Saturday they are higher still: 40% refused, 23% rephrased, 11% asking for a
person. Friday is the only day with two releases in it. The thumbs say the same, less clearly, because
there are only about twenty-five of them a day.

## What the week says, put together

Lesson 3 found that the cost per request fell by half over the week, and most of that after Friday's
release. This lesson finds that from the same moment, customers were refused more, asked again more,
and gave up on the assistant twice as often. **The release made the assistant cheaper by making it
worse**, and only a view with both in it shows that as one event rather than two pieces of news, one
good and one bad.

The decision follows: put the floor back, and work on the order questions some other way (the previous
sections pointed at the search). Lesson 14 is where a change like that gets tested against the
evaluation set before it ships, so that the next release that raises a floor is caught on a pull
request rather than on a Saturday.

## What this view still cannot see

Every number in the table is about **behaviour**: what was refused, what people did next. Not one of
them says whether the replies that were not refused were right. A confident wrong answer, which the
customer believes and acts on, gets no thumb, no rephrasing and no request for a person. It is the
most harmful failure an assistant like this has, and it is invisible to everything in lessons 1 to 5.
Lessons 8 to 13 build the instruments that see it.
