---
title: The judge, measured against people
version: 1
---

With a reference that two people agree on, the judge can be measured the same way they were.
`judge_runs.py` asks judge-1 for a relevance verdict on each of the sixty replies and writes them where
`agree.py` reads them:

```python
"""judge_runs.py: judge-1's relevance verdict on every reply of the two runs, written where agree.py reads it.

    python judge_runs.py [--refusals-pass]

With --refusals-pass the agreed refusal is passed by rule, as the rubric says,
and never sent to the judge.
"""
import argparse
import json

import checks
import judge
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--refusals-pass", action="store_true")
a = p.parse_args()
telemetry.setup("judge-spans.jsonl", service="judge")
asked = total = 0
with open("runs/judged.jsonl", "w") as out:
    for run in ("old", "new"):
        for r in map(json.loads, open(f"runs/{run}.jsonl")):
            if a.refusals_pass and checks.is_refusal(r["reply"]):
                label = "pass"
            else:
                label = judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"]
                asked += 1
            out.write(json.dumps({"case": r["id"], "release": r["release"], "label": label}) + "\n")
            total += 1
print(f"runs/judged.jsonl: {total} replies, {asked} sent to judge-1, {total - asked} passed by rule")
```

```
ana@lab:~/obs$ python judge_runs.py
runs/judged.jsonl: 60 replies, 60 sent to judge-1, 0 passed by rule
ana@lab:~/obs$ python agree.py relevance-v2/agreed judge
60 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      29    24
  fail       7     0
agreement 48.3%   by chance 57.7%   kappa -0.22
apart on 31: 24 refusals, 7 other replies
  e02 2026.09.4  fail / pass  Keep the receipt the post office gives you until the refun
  e04 2026.09.4  fail / pass  We replace damaged books at no cost and you do not need to
  e06 2026.09.4  fail / pass  Express delivery is not free at any order value. [1]
  e06 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e07 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e19 2026.09.4  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
  e19 2026.10.1  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
```

**Kappa is −0.22: the judge agrees with people less often than chance would.** Not because it is
random, but because it is systematically opposite on one kind of reply. Every one of the twenty-four
refusals passes the rubric and fails the judge: a refusal shares no words with the question, so its
similarity is low, and judge-1 calls it irrelevant. The seven replies people failed, it passed.

That changes what lesson 9 found. Judge-1's relevance pass rate fell from 76.6% to 62.3% when the floor
release went out, and the release did make the assistant worse. But lesson 9's full grading says what judge-1
was counting: **every one of the 348 replies it failed that week was the refusal**, and every other reply
passed. The rubric counts a refusal as relevant, and lesson 8 already counted the wrong ones as wrong.
The number moved for a real reason and was labelled with the wrong criterion. That is what a judge
nobody has measured does: it produces a number that moves when things change, and nobody can say what
the number means.

## Fixing what can be fixed by rule

The rubric settles refusals without reading anything: the agreed refusal passes. A rule can apply that
before the judge is called, and `--refusals-pass` does:

```
ana@lab:~/obs$ python judge_runs.py --refusals-pass
runs/judged.jsonl: 60 replies, 36 sent to judge-1, 24 passed by rule
ana@lab:~/obs$ python agree.py relevance-v2/agreed judge
60 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      53     0
  fail       7     0
agreement 88.3%   by chance 88.3%   kappa 0.00
apart on 7: 0 refusals, 7 other replies
  e02 2026.09.4  fail / pass  Keep the receipt the post office gives you until the refun
  e04 2026.09.4  fail / pass  We replace damaged books at no cost and you do not need to
  e06 2026.09.4  fail / pass  Express delivery is not free at any order value. [1]
  e06 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e07 2026.10.1  fail / pass  Express delivery is not free at any order value. [1]
  e19 2026.09.4  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
  e19 2026.10.1  fail / pass  Marginalia is an online bookshop operated at marginalia.ex
```

**Agreement 88.3%, and kappa 0.00.** The judge now agrees with people on 53 replies of 60, and it
agrees exactly as often as a judge that passed everything without reading. Because that is what it
did: every reply judge-1 was sent, it passed. The seven that people failed share the question's words,
and judge-1 measures the words.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Agreement observed and agreement by chance, on an axis from 0 to 100%, with kappa beside each row. Ana and Bruno on version 1: 51.7% against 45.7% by chance, kappa 0.11. On version 2: 96.7% against 76.8%, kappa 0.86. judge-1 against the agreed labels: 48.3% against 57.7%, kappa −0.22. judge-1 with refusals passed by rule: 88.3% against 88.3%, kappa 0.00.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana and Bruno, version 1</text><path d=\"M419.09 48 L441.29 48\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"419.09\" cy=\"48\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"441.29\" cy=\"48\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.11</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana and Bruno, version 2</text><path d=\"M534.16 86 L607.79 86\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"534.16\" cy=\"86\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"607.79\" cy=\"86\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.86</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">judge-1 and the agreed labels</text><path d=\"M428.71 124 L463.49 124\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"463.49\" cy=\"124\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"428.71\" cy=\"124\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ −0.22</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">judge-1 plus the refusal rule</text><path d=\"M576.71 162 L576.71 162\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"576.71\" cy=\"162\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"576.71\" cy=\"162\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.00</text><path d=\"M250 192 L620 192\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M250 192 L250 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"250\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M324 192 L324 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"324\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M398 192 L398 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"398\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M472 192 L472 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"472\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M546 192 L546 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"546\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M620 192 L620 197\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"620\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"435\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">share of the 60 replies on which the two agree</text><circle cx=\"250\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"260\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">observed</text><circle cx=\"361\" cy=\"16\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"371\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">by chance</text></svg>", "caption": "Kappa is the distance from the by-chance dot to the observed one, measured against the room left above the by-chance dot. The last row agrees on 88% of replies and is no better than chance."}
```

This is the case kappa exists for. An agreement of 88% looks like a judge worth trusting, and on a
dashboard it would be reported as one. Kappa says the judge has **not yet caught a single irrelevant
reply**, and the seven listed are exactly the replies a relevance judge is for.

## What the team does next

Three moves, in the order a team makes them, and each is measured again against the same sixty labels:

- **Keep the rule.** Refusals passed by rule cost no judge call: 24 of 60 calls saved, and the most
  common disagreement gone. Lesson 9 priced each call.
- **Change the judge's prompt to the rubric's.** Version 2's anchors are written for people and work
  for a model too: a real judge given the express-delivery example has something to compare against.
  judge-1 is the lab's rules and cannot be prompted into reading, so the lab stops here; with a real
  model, this is the step that moves kappa.
- **Re-measure on every change of judge.** A new judge model, a new prompt, a new threshold: each is
  a different instrument, and the sixty labels say at once whether it agrees with people better or
  worse than the last. Lesson 14 makes that comparison a test.

The labels outlive every judge. That is why they are named by question and release rather than by
trace, and why the rubric's version is written in every line.
