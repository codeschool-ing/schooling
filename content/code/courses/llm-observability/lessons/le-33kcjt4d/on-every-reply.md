---
title: On every reply, in production
version: 1
---

A rule costs microseconds and no tokens, so it can run on **every** reply, not on a sample. Two places
to run it: on the evaluation run, before a change ships, and on the traffic, after.

`check_run.py` counts each check's passes over a run:

```python
"""check_run.py: every check in checks.py on every reply of a run, counted, and the failures listed."""
import json
import sys
from collections import Counter

import checks

run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
failed, examples = Counter(), {}
for r in run:
    for name, ok, why in checks.run(r["reply"], r["sources"]):
        if not ok:
            failed[name] += 1
            examples.setdefault(name, f"{r['id']}: {why}")
for c in checks.CHECKS:
    print(f"{c.__name__:22} {len(run) - failed[c.__name__]:3}/{len(run)} pass   {examples.get(c.__name__, '')}")
```

```
ana@lab:~/obs$ python check_run.py current
cites_every_sentence    30/30 pass   
citations_exist         30/30 pass   
numbers_in_sources      30/30 pass   
no_personal_data        30/30 pass   
refusal_is_exact        30/30 pass   
short_enough            30/30 pass   
```

And `check_week.py` does the same over the replayed week, reading each reply from its root span and its
sources from the chunk ids on its search span, which find their text in the database:

```python
"""check_week.py: the checks on every reply of the replayed week, from the spans, per release."""
import json
from collections import Counter, defaultdict

import psycopg

import checks

text = dict(psycopg.connect().execute("SELECT id, text FROM chunks").fetchall())
by_trace = defaultdict(dict)
for s in map(json.loads, open("spans.jsonl")):
    by_trace[s["trace"]][s["name"]] = s["attributes"]
seen, failed = Counter(), defaultdict(Counter)
for spans in by_trace.values():
    root = spans["ask"]
    if root["app.feature"] == "summary":
        continue
    sources = [{"id": c, "text": text[c]} for c in spans["search"]["app.search.chunks"]]
    release = root["app.release"]
    seen[release] += 1
    for name, ok, _ in checks.run(root["app.reply"], sources):
        failed[release][name] += not ok
print(f"{'check':22}" + "".join(f"{r:>12}" for r in sorted(seen)))
for c in checks.CHECKS:
    print(f"{c.__name__:22}" + "".join(f"{failed[r][c.__name__]:6} fail" for r in sorted(seen)))
print(f"{'replies':22}" + "".join(f"{seen[r]:12}" for r in sorted(seen)))
```

```
ana@lab:~/obs$ python check_week.py
check                    2026.09.4   2026.10.1
cites_every_sentence       0 fail     0 fail
citations_exist            0 fail     0 fail
numbers_in_sources         0 fail     0 fail
no_personal_data           0 fail     0 fail
refusal_is_exact           0 fail     0 fail
short_enough               0 fail     0 fail
replies                        789         432
```

**Not one failure, in thirty replies or in 1,221.** That is extract-1: it copies sentences from its
sources and cites each one, so it cannot break these rules. A real model breaks them now and then: a
citation to a source it was not given, a sentence with none, a number from its training data. The
zeros here are a property of the stand-in, and the lesson does not pretend otherwise.

## Why a rule that never fires is still worth running

Because the day it fires is the day something changed. A new model version, a new prompt, a library
upgrade that formats citations differently: each can start breaking a rule overnight, and the rule is
the alarm. A check with a long record of passing turns from a measurement into a **tripwire**, and a
tripwire's value is not in how often it goes off.

Two things make a tripwire useful rather than ignored:

- **It is recorded where the trace is.** The result of each check goes on the trace as a score, as the
  thumbs did in lessons 6 and 7, with an annotator kind of `CODE`. A reply that fails a check is then
  one click from its prompt and sources.
- **Its rate is watched, not its single failures.** One reply in ten thousand with a stray citation is
  noise. One in fifty, starting on the day of a release, is lesson 16's alert.

## What runs where

| | where | how often | what it costs |
|---|---|---|---|
| rules on the form | in the application, after each reply, or in a job over the traces | every reply | nothing measurable |
| comparison with an expected answer | on the evaluation set, before shipping | every change | the run itself |
| a model as judge (lesson 9) | on a sample of traffic, and on the evaluation set | a share of replies | a model call per reply judged |
| people (lesson 10) | on a smaller sample | weekly | hours |

The order of that table is the order of cost, and it is also the order of trust: the cheaper a check,
the less it can see, and the more of the traffic it can afford to look at.
