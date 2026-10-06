---
title: A threshold is a trade
version: 1
---

judge-1 answers relevance with a score as well as a verdict, and its verdict is the score against a
threshold of 0.40 that the lab chose. Lesson 10 found that at 0.40 it never flags anything people call
irrelevant. The threshold is a setting, though, and every judge that returns a score has one, so the
question is fair: **at which threshold would it be a useful detector?**

`sweep.py` scores the 36 replies the judge reads; the refusals are passed by rule, as lesson 10 decided. It counts, at six thresholds, how many it would flag and how many of those people failed:

```python
"""sweep.py: judge-1's relevance score used to flag irrelevant replies, at six thresholds,
against the agreed labels of lesson 10. A flag is a score below the threshold."""
import json

import checks
import judge
import telemetry

telemetry.setup("judge-spans.jsonl", service="judge")
agreed = {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("data/labels.jsonl"))
          if r["rubric"] == "relevance-v2" and r["rater"] == "agreed"}
scored = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        if checks.is_refusal(r["reply"]):
            continue   # passed by rule, as in lesson 10
        score = judge.grade("relevance", r["question"], r["reply"], r["sources"])["score"]
        scored.append((score, agreed[r["id"], r["release"]] == "fail"))
bad = sum(b for _, b in scored)
print(f"{len(scored)} replies read by the judge, {bad} of them irrelevant by the agreed labels")
print("threshold  flagged  caught  precision  recall")
for t in (0.40, 0.55, 0.60, 0.65, 0.70, 0.75):
    flagged = [b for s, b in scored if s < t]
    caught = sum(flagged)
    precision = f"{caught / len(flagged):9.0%}" if flagged else "        -"
    print(f"     {t:.2f}  {len(flagged):7}  {caught:6}  {precision}  {caught / bad:6.0%}")
```

```
ana@lab:~/obs$ python sweep.py
36 replies read by the judge, 7 of them irrelevant by the agreed labels
threshold  flagged  caught  precision  recall
     0.40        0       0          -      0%
     0.55        1       1       100%     14%
     0.60        6       2        33%     29%
     0.65        9       4        44%     57%
     0.70       13       7        54%    100%
     0.75       19       7        37%    100%
```

Reading down the table is moving the threshold up, and both columns move:

- **At 0.40 nothing is flagged.** Precision has nothing to be about, and recall is zero: the judge of
  lesson 10.
- **At 0.55 one reply is flagged, and it is bad.** Perfect precision, and six of the seven bad replies
  are missed.
- **At 0.70 all seven are caught**, among thirteen flagged: recall 100%, precision 54%. Six replies
  people passed are flagged with them.
- **At 0.75 the extra flags are all false alarms.** Recall cannot rise further, and precision falls.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Precision and recall of judge-1's relevance score as a detector, at thresholds from 0.40 to 0.75. Recall climbs from 0% at 0.40 to 100% at 0.70 and stays there. Precision is undefined at 0.40, 100% at 0.55 on a single flag, then 33%, 44%, 54% at 0.70, and falls to 37% at 0.75.\"><path d=\"M90 210 L660 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 210 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M85 210 L90 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M85 125 L90 125\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M85 40 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M90 210 L90 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.40</text><path d=\"M334.286 210 L334.286 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"334.286\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.55</text><path d=\"M415.714 210 L415.714 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"415.714\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.60</text><path d=\"M497.143 210 L497.143 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.143\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.65</text><path d=\"M578.571 210 L578.571 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"578.571\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.70</text><path d=\"M660 210 L660 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.75</text><text x=\"375\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">threshold: a reply scoring below it is flagged</text><path d=\"M90 210 L334.286 186.2 L415.714 160.7 L497.143 113.1 L578.571 40 L660 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M334.286 40 L415.714 153.9 L497.143 135.2 L578.571 118.2 L660 147.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"210\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"334.286\" cy=\"186.2\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"415.714\" cy=\"160.7\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"497.143\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"578.571\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"334.286\" cy=\"40\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"415.714\" cy=\"153.9\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"497.143\" cy=\"135.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"578.571\" cy=\"118.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"147.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"100\" cy=\"16\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"110\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">precision</text><circle cx=\"220\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"230\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">recall</text></svg>", "caption": "Every step to the right catches more bad replies and flags more good ones. At 0.40, the lab's setting, nothing is flagged at all."}
```

0.70 looks best on this table, and it would be a mistake to adopt it from this table. **Seven bad
replies are too few to choose a threshold with.** The scores of the bad ones (0.54 to 0.68) overlap the
scores of good ones (0.55 to 0.90) because judge-1 measures shared words. A threshold tuned on sixty replies to catch exactly these seven is fitted to them. A team does this with a few hundred
labelled replies, and checks the chosen threshold on labels it did not tune on, which is lesson 13's
split between a development set and a held-out one.

## Which way to err

The threshold is chosen by **what each kind of error costs**, and that depends on what the detector
drives:

- **An alert that wakes somebody** needs precision. A detector that is wrong half the time it fires
  is muted within a week, and then it catches nothing at all. Lesson 16 sets alerts with this in
  mind.
- **A gate that blocks a release** needs recall. A bad reply that slips through reaches customers; a
  false alarm costs somebody the time to read the flagged replies and override it. Lesson 15 builds
  the gate.
- **A queue for people to read** sits in between. Its size is somebody's afternoon, so precision decides
  how much of it is wasted, and recall decides how much it misses.

So the same judge can be run at two thresholds for two purposes, and that is not inconsistency. Each
threshold is written down beside the purpose it serves, with the precision and recall it had on the
labels the day it was chosen.
