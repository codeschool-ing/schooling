---
title: Three ways to choose
version: 2
---

`sample.py` holds three rules for choosing which replies to grade:

```python
"""sample.py: which replies of the week to grade, by three different rules."""
import hashlib
import random


def keep(trace, share):
    """Random but repeatable: the same trace is in or out on every run, decided by its id."""
    return int(hashlib.sha256(trace.encode()).hexdigest()[:8], 16) / 0xFFFFFFFF < share


def uniform(replies, share):
    return [r for r in replies if keep(r["trace"], share)]


def stratified(replies, per_group, key=lambda r: (r["release"], r["feature"])):
    """The same number from every group, so a small group is not drowned by a large one."""
    groups = {}
    for r in replies:
        groups.setdefault(key(r), []).append(r)
    rng = random.Random(7)
    return [r for g in sorted(groups) for r in rng.sample(groups[g], min(per_group, len(groups[g])))]


def targeted(replies):
    """Every reply somebody already doubted: a thumb down, or a refusal."""
    return [r for r in replies if r["thumb"] == "down" or r["outcome"] == "refused"]
```

**Uniform** takes a fixed share of everything. The choice is made from a hash of the trace id rather
than a random number, so a rerun picks the same replies, and two people grading "the 10% sample" grade
the same thing. **Stratified** takes the same number from every group, here every combination of
release and feature. **Targeted** takes every reply somebody already doubted: a thumb down, or a
refusal.

`grade_sample.py` grades whichever is chosen and reports a pass rate per release, with its 95%
interval:

```python
"""grade_sample.py: the judge on a sample of the week, pass rates per release with how sure they are."""
import argparse
import json
import math
import time
from collections import Counter

import judge
import sample
import telemetry
import week

p = argparse.ArgumentParser()
p.add_argument("how", choices=["uniform", "stratified", "targeted"])
p.add_argument("--share", type=float, default=0.1)
p.add_argument("--per-group", type=int, default=30)
a = p.parse_args()


def wilson(passed, n, z=1.96):
    """The 95% interval for a pass rate measured on n replies."""
    if n == 0:
        return 0.0, 1.0
    p = passed / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return centre - half, centre + half


replies = list(week.replies())
chosen = {"uniform": lambda: sample.uniform(replies, a.share),
          "stratified": lambda: sample.stratified(replies, a.per_group),
          "targeted": lambda: sample.targeted(replies)}[a.how]()
telemetry.setup("judge-spans.jsonl", service="judge")
started = time.monotonic()
passed, seen, unreadable = Counter(), Counter(), Counter()
with open("verdicts.jsonl", "a") as out:
    for r in chosen:   # one at a time: a judge on the same machine as the assistant competes with it
        v = judge.grade("relevance", r["question"], r["reply"], r["sources"])
        out.write(json.dumps({"trace": r["trace"], "sample": a.how, **v}) + "\n")
        if v["verdict"] == "unreadable":
            unreadable[r["release"]] += 1
            continue
        seen[r["release"]] += 1
        passed[r["release"]] += v["verdict"] == "pass"
print(f"{a.how}: {len(chosen)} of {len(replies)} replies graded for relevance in "
      f"{(time.monotonic() - started) / 60:.1f} min, {sum(unreadable.values())} verdicts unreadable")
for rel in sorted(seen):
    lo, hi = wilson(passed[rel], seen[rel])
    print(f"  {rel}  {passed[rel]:4}/{seen[rel]:<4} pass  {passed[rel] / seen[rel]:5.1%}   95% between {lo:5.1%} and {hi:5.1%}")
```

```
ana@dev:~/obs$ python grade_sample.py uniform --share 0.1
uniform: 23 of 275 replies graded for relevance in 2.1 min, 0 verdicts unreadable
  2026.09.4     3/10   pass  30.0%   95% between 10.8% and 60.3%
  2026.10.1     2/13   pass  15.4%   95% between  4.3% and 42.2%
```

```
ana@dev:~/obs$ python grade_sample.py stratified --per-group 30
stratified: 120 of 275 replies graded for relevance in 10.6 min, 0 verdicts unreadable
  2026.09.4    28/60   pass  46.7%   95% between 34.6% and 59.1%
  2026.10.1    20/60   pass  33.3%   95% between 22.7% and 45.9%
```

```
ana@dev:~/obs$ python grade_sample.py targeted
targeted: 90 of 275 replies graded for relevance in 7.7 min, 0 verdicts unreadable
  2026.09.4     1/32   pass   3.1%   95% between  0.6% and 15.7%
  2026.10.1     0/58   pass   0.0%   95% between  0.0% and  6.2%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Relevance pass rates per release, as dots with 95% intervals, on an axis from 0 to 100%. Every reply: 43.3% before the release and 34.0% after, with intervals that overlap. A uniform 10% sample: 30.0% and 15.4%, with intervals so wide they cover most of the axis. Thirty per group: 46.7% and 33.3%, a little high for the first release. Targeted: 3.1% and 0.0%, nowhere near the week.\"><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every reply</text><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 275</text><path d=\"M353.04 40 L438.84 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"395.16\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M308.84 56 L389.44 56\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"346.8\" cy=\"56\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uniform 10%</text><text x=\"20\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 23</text><path d=\"M226.16 84 L483.56 84\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"326.0\" cy=\"84\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M192.36 100 L389.44 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"250.08\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">30 per group</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 120</text><path d=\"M349.92 128 L477.32 128\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"412.84\" cy=\"128\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M288.04 144 L408.68 144\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"343.16\" cy=\"144\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">targeted</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">n = 90</text><path d=\"M173.12 172 L251.64 172\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"186.12\" cy=\"172\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M170.0 188 L202.24 188\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"188\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><path d=\"M170 218 L690 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 218 L170 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M274 218 L274 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"274\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M378 218 L378 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"378\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M482 218 L482 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"482\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M586 218 L586 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"586\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M690 218 L690 223\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"430\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">share of replies the judge passes for relevance</text><circle cx=\"190.8\" cy=\"14\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"200.8\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2026.09.4</text><circle cx=\"305.2\" cy=\"14\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"315.2\" y=\"14\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2026.10.1</text></svg>", "caption": "Only the first row is the week. The others are what three ways of sampling would have reported, and how sure each could be."}
```

**Uniform is unbiased and nearly useless at this size.** A tenth of 275 is 23 replies, and 30.0% and
15.4% come with intervals from 10.8% to 60.3% and from 4.3% to 42.2%. Both of the week's values are
inside them, which is all an unbiased sample promises. Neither interval can tell the releases apart, or
tell a judge that passes a third of the replies from one that passes half.

**Stratified is close, and biased upwards.** 46.7% and 33.3%, against the week's 43.3% and 34.0%.
Thirty replies from each feature in each release means the `order` requests, a quarter of the week,
are half the sample, and this judge passes `order` replies more often than `help` ones: 43% against
37%, over the whole week. An equal number per group is the right way to learn about each group, and
the wrong way to estimate the whole unless every group's result is weighted back by its share of the
traffic. Stratifying and forgetting to reweight is a common way to report a number nobody measured.

**Targeted is not an estimate of anything**: 3.1% and 0.0%. It chose every reply somebody already
doubted, a thumb down or a refusal, and the judge failed all of them but one. Most of those are the
refusals it fails by habit, so here the targeted sample measures the judge as much as the assistant.
That is its other use: it finds failures to read, debug and turn into test cases, lesson 13's subject,
and it finds where the judge is wrong. Its pass rate must never be put on a dashboard as "quality",
because it measures the sampling rule.

## Which to use

All three, for different questions. A **uniform** sample for the number that goes on the dashboard. A
**stratified** sample, reweighted, when a small group matters on its own, such as a feature with little
traffic that would get three replies in a uniform tenth. A **targeted** sample for the reading list,
with its results kept apart from the others. And the rule that decided each sample stored with its
verdicts, as `grade_sample.py` does in `verdicts.jsonl`, so that nobody later averages them together.
