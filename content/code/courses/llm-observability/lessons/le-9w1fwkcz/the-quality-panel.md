---
title: The quality panel
version: 2
---

Lesson 5 found the floor release by reading the week after it happened. A dashboard and an alert are
how a team finds the next one while it is happening. Both are built from the same few numbers, and
this lesson builds them from the replayed week, ending where the course began: with somebody being
told that the assistant got worse, in time to do something about it.

`replies.py` turns the week's root spans into one record per customer reply: when, which release, which
feature, whether it was the agreed refusal, and the thumb if there was one. `series.py` is a dashboard's
quality panel as numbers, one line per twelve hours:

```python
"""replies.py: the week's answered and refused customer replies, one record each, from the root spans and the thumbs."""
import json
from datetime import datetime

import checks

thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}


def week():
    out = []
    for s in map(json.loads, open("spans.jsonl")):
        a = s["attributes"]
        if s["name"] != "ask" or a["app.feature"] == "summary":
            continue
        out.append({"at": datetime.fromtimestamp(s["start"] / 1e9), "release": a["app.release"],
                    "feature": a["app.feature"], "refused": checks.is_refusal(a["app.reply"]),
                    "thumb": thumbs.get(s["trace"])})
    return sorted(out, key=lambda r: r["at"])
```

```python
"""series.py: the dashboard's quality panel as numbers: per twelve hours, how many replies, and how many refused."""
from collections import defaultdict

import replies

slots = defaultdict(list)
for r in replies.week():
    slots[r["at"].strftime("%a %d ") + f"{r['at'].hour // 12 * 12:02d}h"].append(r)
print("twelve hours from   replies  refused         thumbs down")
for slot, rs in slots.items():
    refused, voted = sum(r["refused"] for r in rs), [r for r in rs if r["thumb"]]
    down = sum(r["thumb"] == "down" for r in voted)
    release = " " + rs[-1]["release"] if rs[0]["release"] != rs[-1]["release"] else ""
    print(f"  {slot:16} {len(rs):8} {refused:6} {refused / len(rs):5.0%}   {down:4} of {len(voted):3}{release}")
```

```
ana@dev:~/obs$ python series.py
twelve hours from   replies  refused         thumbs down
  Mon 28 00h             14      2   14%      1 of   4
  Mon 28 12h             25      9   36%      2 of   6
  Tue 29 00h             14      4   29%      1 of   2
  Tue 29 12h             28      4   14%      0 of  11
  Wed 30 00h             16      3   19%      1 of   2
  Wed 30 12h             26      5   19%      0 of   7
  Thu 01 00h             16      5   31%      0 of   2 2026.10.1
  Thu 01 12h             33     20   61%      1 of   4
  Fri 02 00h             16      4   25%      0 of   5
  Fri 02 12h             24      9   38%      2 of   6
  Sat 03 00h             13      7   54%      1 of   1
  Sat 03 12h             19      7   37%      1 of   4
  Sun 04 00h             11      2   18%      0 of   3
  Sun 04 12h             21      7   33%      0 of   1
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Share of replies refused in each twelve hours of the week, from Monday 28 September to Sunday 4 October, with the baseline of 23.1% as a dashed line and the release of Thursday at 10:00 marked. Before the release the share sits between 14% and 36%. The twelve hours after it reach 61%, and the share stays between 18% and 54% to the end of the week.\"><path d=\"M60 220 L700 220\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M60 220 L60 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M55 220.0 L60 220.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M55 170.0 L60 170.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M55 120.0 L60 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M55 70.0 L60 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"51\" y=\"70.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"105.714\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mon</text><text x=\"197.143\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Tue</text><text x=\"288.571\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Wed</text><text x=\"380.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Thu</text><text x=\"471.429\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Fri</text><text x=\"562.857\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat</text><text x=\"654.286\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sun</text><path d=\"M60 162.25 L700 162.25\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"696\" y=\"174.25\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">baseline 23.1%</text><path d=\"M372.38 220 L372.38 44\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"378.38\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2026.10.1 goes out</text><path d=\"M82.86 185.0 L128.57 130.0 L174.29 147.5 L220.0 185.0 L265.71 172.5 L311.43 172.5 L357.14 142.5 L402.86 67.5 L448.57 157.5 L494.29 125.0 L540.0 85.0 L585.71 127.5 L631.43 175.0 L677.14 137.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"82.86\" cy=\"185.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"128.57\" cy=\"130.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"174.29\" cy=\"147.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"220.0\" cy=\"185.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"265.71\" cy=\"172.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"311.43\" cy=\"172.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"357.14\" cy=\"142.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"402.86\" cy=\"67.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"448.57\" cy=\"157.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"494.29\" cy=\"125.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"540.0\" cy=\"85.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"585.71\" cy=\"127.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"631.43\" cy=\"175.0\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"677.14\" cy=\"137.5\" r=\"3.5\" fill=\"var(--phosphor)\" stroke=\"none\"></circle></svg>", "caption": "Refused, as a share of replies, every twelve hours. The twelve hours after the release refuse three questions in five."}
```

Four things about this panel make it a panel worth having, and each is a rule from earlier in the course:

- **The volume is beside the rate.** Each window holds 11 to 33 replies, so one refusal moves a window
  by three to nine points. Saturday morning's 54% is seven refusals in thirteen. Lesson 5's rule: a rate
  with no count beside it invites a reading nobody should make.
- **The release is on it.** The line that names 2026.10.1 is the twelve hours in which the release
  changed, and every number after it belongs to the new release. A quality chart with no release marked
  asks the reader to remember what shipped when.
- **The thumbs are counted, and they are few.** Between 1 and 11 votes in twelve hours, and ten thumbs
  down in the whole week. Nobody could alert on them at this volume: that is lesson 9's
  arithmetic.
- **The refusal is counted by its exact text**, lesson 8's rule. A refusal in other words would be
  invisible here, which is why that check runs on every reply.

What the panel cannot show is a confident wrong answer, the failure lessons 8 to 12 measured. That
needs the evaluation pipeline, with its sampled judge and its n, on a panel of its own beside this one.
