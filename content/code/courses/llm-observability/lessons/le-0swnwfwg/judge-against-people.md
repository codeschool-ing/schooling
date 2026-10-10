---
title: The judge, measured against people
version: 2
---

With a reference that two people agree on, the judge can be measured the same way they were.
`judge_runs.py` asks lesson 9's judge for a relevance verdict on each of the forty-eight replies and
writes them where `agree.py` reads them:

```python
"""judge_runs.py: the judge's relevance verdict on every reply of the two runs, written where agree.py reads it.

    python judge_runs.py [--refusals-by-key] [--rubric data/rubrics/relevance-v2.md]

--refusals-by-key decides the agreed refusal without the judge, as version 2
of the rubric says: it passes when the evaluation set has no facts for the
question, so the documents do not answer it, and fails when it has some.
--rubric gives the judge that file in place of judge.py's own sentence.
"""
import argparse
import json

import checks
import judge
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--refusals-by-key", action="store_true")
p.add_argument("--rubric")
a = p.parse_args()
if a.rubric:
    judge.RUBRIC["relevance"] = open(a.rubric).read()
facts = {c["id"]: c["facts"] for c in map(json.loads, open("data/eval.jsonl"))}
telemetry.setup("judge-spans.jsonl", service="judge")
asked = total = 0
with open("runs/judged.jsonl", "w") as out:
    for run in ("old", "new"):
        for r in map(json.loads, open(f"runs/{run}.jsonl")):
            if a.refusals_by_key and checks.is_refusal(r["reply"]):
                label = "fail" if facts[r["id"]] else "pass"
            else:
                label = judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"]
                asked += 1
            out.write(json.dumps({"case": r["id"], "release": r["release"], "label": label}) + "\n")
            total += 1
print(f"runs/judged.jsonl: {total} replies, {asked} sent to the judge, {total - asked} decided by the key")
```

```
ana@dev:~/obs$ python judge_runs.py
runs/judged.jsonl: 48 replies, 48 sent to the judge, 0 decided by the key
ana@dev:~/obs$ python agree.py relevance-v2/agreed judge
48 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      20    21
  fail       0     7
agreement 56.2%   by chance 44.1%   kappa 0.22
apart on 21: 10 refusals, 11 other replies
  e01 2026.10.1  pass / fail  You have 30 days from the date of delivery to return a pri
  e02 2026.10.1  pass / fail  According to [1], the customer pays for the return postage
  e03 2026.09.4  pass / fail  According to [1], we refund within three working days of t
  e03 2026.10.1  pass / fail  According to [1], we refund within three working days of t
  e04 2026.09.4  pass / fail  According to [1], signed copies are items that cannot be r
  e07 2026.09.4  pass / fail  According to source [1], standard delivery is free on orde
  e08 2026.09.4  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e08 2026.10.1  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e11 2026.09.4  pass / fail  You can read your e-books on up to six devices at the same
  e16 2026.09.4  pass / fail  According to [1], payments-and-invoices, every order comes
  e16 2026.10.1  pass / fail  You will receive the invoice for your order as soon as it 
  e20 2026.09.4  pass / fail  I could not find that in our documents.
  e20 2026.10.1  pass / fail  I could not find that in our documents.
  e21 2026.09.4  pass / fail  I could not find that in our documents.
  e21 2026.10.1  pass / fail  I could not find that in our documents.
  e22 2026.09.4  pass / fail  I could not find that in our documents.
  e22 2026.10.1  pass / fail  I could not find that in our documents.
  e23 2026.09.4  pass / fail  I could not find that in our documents.
  e23 2026.10.1  pass / fail  I could not find that in our documents.
  e24 2026.09.4  pass / fail  I could not find that in our documents.
  e24 2026.10.1  pass / fail  I could not find that in our documents.
```

**Kappa is 0.22**, and the judge's disagreements with people are of two kinds:

- **It failed every refusal**, as lesson 9 found: the ten right ones, to questions the documents do
  not answer, and the seven wrong ones, which people failed too. The judge cannot tell them apart,
  because nothing in what it is shown says whether the documents answer the question. A refusal comes
  with no sources at all.
- **It failed eleven replies that answer the question**: the return window, the refund time, the price
  of express delivery, the invoice. These are not hard cases. People passed every one of them under
  both versions of the rubric.

That changes what lesson 9's numbers meant. The judge's relevance pass rate fell from 43.3% to 34.0%
across the release, and the release did refuse more: but every refusal counted as a failure, the right
ones included, and about a third of the answers counted as failures too. The number moved for a real
reason and was made of the wrong things. That is what a judge nobody has measured does: it produces a
number that moves when things change, and nobody can say what the number means.

## Deciding what can be decided by rule

Version 2 settles refusals without reading the reply: the agreed refusal passes if the documents do not
answer the question, and fails if they do. Whether they do is in the evaluation set, as the facts of
each question, so a rule can decide every refusal before the judge is called. `--refusals-by-key` does:

```
ana@dev:~/obs$ python judge_runs.py --refusals-by-key
runs/judged.jsonl: 48 replies, 31 sent to the judge, 17 decided by the key
ana@dev:~/obs$ python agree.py relevance-v2/agreed judge
48 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      30    11
  fail       0     7
agreement 77.1%   by chance 58.9%   kappa 0.44
apart on 11: 0 refusals, 11 other replies
  e01 2026.10.1  pass / fail  You have 30 days from the date of delivery to return a pri
  e02 2026.10.1  pass / fail  According to [1], the customer pays for the return postage
  e03 2026.09.4  pass / fail  According to [1], we refund within three working days of t
  e03 2026.10.1  pass / fail  According to [1], we refund within three working days of t
  e04 2026.09.4  pass / fail  According to [1], signed copies are items that cannot be r
  e07 2026.09.4  pass / fail  According to source [1], standard delivery is free on orde
  e08 2026.09.4  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e08 2026.10.1  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e11 2026.09.4  pass / fail  You can read your e-books on up to six devices at the same
  e16 2026.09.4  pass / fail  According to [1], payments-and-invoices, every order comes
  e16 2026.10.1  pass / fail  You will receive the invoice for your order as soon as it 
```

**Kappa 0.44**, from 0.22, and seventeen judge calls saved, one in three. Every refusal is now right by
construction, and what remains is the judge's own: the eleven answers it fails. That is the honest
size of this judge's problem, and it is now a list that can be read.

## Giving the judge the people's rubric

The obvious next move is to give the judge what the people were given: version 2, with its anchors,
in place of the one sentence `judge.py` sends. `--rubric` does that, and the refusals stay with the
rule:

```
ana@dev:~/obs$ python judge_runs.py --refusals-by-key --rubric data/rubrics/relevance-v2.md
runs/judged.jsonl: 48 replies, 31 sent to the judge, 17 decided by the key
ana@dev:~/obs$ python agree.py relevance-v2/agreed judge
48 replies; rows relevance-v2/agreed, columns judge
          pass  fail
  pass      13    28
  fail       0     7
agreement 41.7%   by chance 33.8%   kappa 0.12
apart on 28: 0 refusals, 28 other replies
  e01 2026.09.4  pass / fail  According to [1], you have 30 days from delivery to return
  e01 2026.10.1  pass / fail  You have 30 days from the date of delivery to return a pri
  e02 2026.09.4  pass / fail  According to [1], returns are free, and you will receive a
  e02 2026.10.1  pass / fail  According to [1], the customer pays for the return postage
  e03 2026.09.4  pass / fail  According to [1], we refund within three working days of t
  e03 2026.10.1  pass / fail  According to [1], we refund within three working days of t
  e04 2026.09.4  pass / fail  According to [1], signed copies are items that cannot be r
  e06 2026.09.4  pass / fail  According to source [1], standard delivery takes three to 
  e06 2026.10.1  pass / fail  According to [1], standard delivery takes three to six wor
  e07 2026.09.4  pass / fail  According to source [1], standard delivery is free on orde
  e07 2026.10.1  pass / fail  According to [1], standard delivery is free on orders over
  e08 2026.09.4  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e08 2026.10.1  pass / fail  According to source [1], express delivery costs R$ 29.90.
  e09 2026.09.4  pass / fail  According to [1], a standard parcel is considered lost whe
  e09 2026.10.1  pass / fail  According to [1], a standard parcel is considered lost whe
  e10 2026.09.4  pass / fail  According to [1], a pickup point keeps a parcel for 10 day
  e10 2026.10.1  pass / fail  According to [1], a pickup point keeps a parcel for 10 day
  e11 2026.09.4  pass / fail  You can read your e-books on up to six devices at the same
  e13 2026.09.4  pass / fail  According to [1], audiobooks can be played in the app, on 
  e14 2026.09.4  pass / fail  Yes, you can pay in instalments. According to [1], on a cr
  e15 2026.09.4  pass / fail  According to [1], an order paid by bank slip ships after t
  e15 2026.10.1  pass / fail  According to [1], an order paid by bank slip ships after t
  e16 2026.09.4  pass / fail  According to [1], payments-and-invoices, every order comes
  e16 2026.10.1  pass / fail  You will receive the invoice for your order as soon as it 
  e17 2026.09.4  pass / fail  According to [1], a gift card is valid for two years from 
  e17 2026.10.1  pass / fail  According to [1], a gift card is valid for two years from 
  e18 2026.09.4  pass / fail  According to [1], if the order costs more than the card ho
  e19 2026.09.4  pass / fail  According to [1], the statutory right of withdrawal is sev
```

**It got worse. Kappa 0.12, and the judge now fails 28 of the 31 replies it reads**, nearly every
answer, where it failed 11 with its own sentence. A rubric written for people, with its distinctions
between relevance and faithfulness and its examples of both, is a longer and harder prompt, and a
model of three billion parameters made less of it than of one plain question. It is not a law that
anchors hurt a judge; with a larger model they often help. It is a result on this judge, and without
forty-eight labels nobody would have known that the change everybody would make first made the
measurement worse.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Agreement observed and agreement by chance, on an axis from 0 to 100%, with kappa beside each row. Ana and Bruno on version 1: 64.6% against 64.6% by chance, kappa 0.00. On version 2: 93.8% against 79.5%, kappa 0.69. The judge against the agreed labels: 56.2% against 44.1%, kappa 0.22. With refusals decided by the answer key: 77.1% against 58.9%, kappa 0.44. Given the people's rubric as well: 41.7% against 33.8%, kappa 0.12.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana and Bruno, version 1</text><path d=\"M489.02 48 L489.02 48\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"489.02\" cy=\"48\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"489.02\" cy=\"48\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.00</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ana and Bruno, version 2</text><path d=\"M544.15 86 L597.06 86\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"544.15\" cy=\"86\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"597.06\" cy=\"86\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.69</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the judge, alone</text><path d=\"M413.17 124 L457.94 124\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"413.17\" cy=\"124\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"457.94\" cy=\"124\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.22</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the judge, refusals by key</text><path d=\"M467.93 162 L535.27 162\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"467.93\" cy=\"162\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"535.27\" cy=\"162\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.44</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and the people's rubric</text><path d=\"M375.06 200 L404.29 200\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"375.06\" cy=\"200\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><circle cx=\"404.29\" cy=\"200\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"700\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">κ 0.12</text><path d=\"M250 230 L620 230\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M250 230 L250 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"250\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M324 230 L324 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"324\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20%</text><path d=\"M398 230 L398 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"398\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><path d=\"M472 230 L472 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"472\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><path d=\"M546 230 L546 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"546\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80%</text><path d=\"M620 230 L620 235\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"620\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"435\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">share of the 48 replies on which the two agree</text><circle cx=\"250\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"260\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">observed</text><circle cx=\"361\" cy=\"16\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\"></circle><text x=\"371\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">by chance</text></svg>", "caption": "Kappa is the distance from the by-chance dot to the observed one, measured against the room left above the by-chance dot. The first row agrees on two replies in three and is no better than chance."}
```

This is the case kappa exists for, and the figure shows why it is not agreement. The last row agrees
with people on 42% of the replies; the third agrees on 56%; the fourth on 77%. Each would look like a
judge somebody could report. Kappa puts them in the right order, and says that the best of them is
still far from the people's 0.69.

## What the team does next

Three moves, in the order a team makes them, and each is measured again against the same forty-eight
labels:

- **Keep the rule.** Refusals decided by the answer key cost no judge call, and are right every time
  the key is.
- **Keep the judge's own sentence**, until a prompt measures better. A change to a judge is a change
  to an instrument, and this one was a change for the worse.
- **Try a better judge**, a larger model or another one, and measure it the same way. A judge that
  is a different model from the assistant also stops sharing its blind spots. Comparing two judges
  against the same labels is the same exercise as this section, run twice.

The labels outlive every judge. That is why they are named by question and release rather than by
trace, and why the rubric's version is written beside every verdict.
