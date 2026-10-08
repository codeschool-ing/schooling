---
title: A threshold is a trade
version: 2
---

Lesson 10 measured the judge's verdicts against people and found them weak. A verdict is one
threshold on one judgement, though, and a detector has a setting. The question is fair: **at which
threshold would this judge be a useful detector?**

A judge's verdict is pass or fail, but `judge.py` also asks for a **score** from 0 to 1, and a score
can be turned into a detector at any threshold: flag every reply that scores below it. `sweep.py`
scores the forty-eight replies of lesson 10 and counts, at six thresholds, how many it would flag and
how many of those people failed:

```python
"""sweep.py: the judge's relevance score used to flag the replies people failed, at several thresholds,
against the agreed labels of lesson 10. A flag is a score below the threshold."""
import json

import judge
import telemetry

telemetry.setup("judge-spans.jsonl", service="judge")
agreed = {(r["case"], r["release"]): r["relevance-v2"]["agreed"] for r in map(json.loads, open("data/labels.jsonl"))}
scored = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        score = judge.grade("relevance", r["question"], r["reply"], r["sources"])["score"]
        scored.append((score, agreed[r["id"], r["release"]] == "fail"))
bad = sum(b for _, b in scored)
print(f"{len(scored)} replies scored by the judge, {bad} of them failed by the agreed labels")
print("scores given:", sorted(set(s for s, _ in scored)))
print("threshold  flagged  caught  precision  recall")
for t in (0.1, 0.3, 0.5, 0.7, 0.9, 1.0):
    flagged = [b for s, b in scored if s < t]
    caught = sum(flagged)
    precision = f"{caught / len(flagged):9.0%}" if flagged else "        -"
    print(f"     {t:.2f}  {len(flagged):7}  {caught:6}  {precision}  {caught / bad:6.0%}")
```

```
ana@dev:~/obs$ python sweep.py
48 replies scored by the judge, 7 of them failed by the agreed labels
scores given: [0, 0.5, 0.6, 0.67, 0.8, 0.9]
threshold  flagged  caught  precision  recall
     0.10       15       4        27%     57%
     0.30       15       4        27%     57%
     0.50       15       4        27%     57%
     0.70       29       4        14%     57%
     0.90       47       7        15%    100%
     1.00       48       7        15%    100%
```

**There is no threshold at which this judge is a detector worth having.** Read the first line: the
judge used only six scores for forty-eight replies, and fifteen of them got 0.

- **Up to 0.50 the same fifteen are flagged**, the replies it scored 0, and four are bad. The other
  eleven are the ten right refusals and one right answer. Precision 27%, recall 57%.
- **At 0.70 fourteen more are flagged**, all good. Precision falls to 14% and recall does not move.
- **At 0.90 everything but one reply is flagged**, and recall reaches 100% the way it always can, by
  flagging the lot.

And the scores do not hold still. Run `sweep.py` twice and the set of scores changes: on a second run
the same judge gave 0.2 to a reply it had scored higher, and gave 0.8 to three refusals while calling
each of them a fail in the same answer. **A score that disagrees with its own verdict is not a
measurement**, and a threshold drawn on it divides nothing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Precision and recall of the judge's relevance score as a detector of the replies people failed, at thresholds from 0.1 to 1.0. Recall is 57% up to 0.7 and 100% from 0.9, where nearly every reply is flagged. Precision is 27% up to 0.5 and falls to 14% and 15% after it. The two lines never trade against each other.\"><path d=\"M90 210 L660 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M90 210 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M85 210 L90 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><path d=\"M85 125 L90 125\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"125\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50%</text><path d=\"M85 40 L90 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><path d=\"M90 210 L90 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"90\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M216.67 210 L216.67 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"216.67\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3</text><path d=\"M343.33 210 L343.33 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"343.33\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M470 210 L470 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"470\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M596.67 210 L596.67 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"596.67\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.9</text><path d=\"M660 210 L660 215\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"660\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.0</text><text x=\"375\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">threshold: a reply scoring below it is flagged</text><path d=\"M90 113.1 L216.67 113.1 L343.33 113.1 L470 113.1 L596.67 40 L660 40\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"216.67\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"343.33\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"470\" cy=\"113.1\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"596.67\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><path d=\"M90 164.1 L216.67 164.1 L343.33 164.1 L470 186.2 L596.67 184.5 L660 184.5\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"90\" cy=\"164.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"216.67\" cy=\"164.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"343.33\" cy=\"164.1\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"470\" cy=\"186.2\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"596.67\" cy=\"184.5\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"660\" cy=\"184.5\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"100\" cy=\"16\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"110\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">precision</text><circle cx=\"220\" cy=\"16\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><text x=\"230\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">recall</text></svg>", "caption": "A detector worth tuning shows the two lines crossing as the threshold moves. These two sit flat and then jump together, because the scores do not rank the replies."}
```

That is the first thing to check before choosing a threshold: **that the score ranks the replies at
all.** A detector earns a precision-recall trade only when bad replies tend to score lower than good
ones, so that moving the threshold moves the two numbers against each other. Here the refusals the
judge cannot judge sit at 0 with the bad ones, and everything else is noise between 0.5 and 0.9. Compare
the rule of lesson 10, which decides refusals from the answer key: on refusals its precision and recall
are both 100%, because it is reading the one fact that decides them.

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
