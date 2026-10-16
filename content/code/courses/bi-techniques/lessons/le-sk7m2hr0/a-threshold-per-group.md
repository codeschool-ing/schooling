---
title: A threshold per group
version: 1
---

The quickest fix an analyst can make without retraining anything is to **move the threshold for the
group the model is wrong about**. If the North's loyal customers get risks that are too high, demand a
higher risk before flagging anybody in the North. The program tries it on lesson 17's scores.

```schooling-example
{"language": "python", "file": "north_threshold.py", "parts": [{"code": "import pandas as pd\n\nscored = pd.read_csv(\"scored.csv\", index_col=\"customer\")\nnorth = scored[scored[\"region\"] == \"North\"]\nstayed, churned = north[north[\"churned\"] == 0], north[north[\"churned\"] == 1]", "note": "Lesson 17's scores again, for the North only."}, {"code": "print(\"threshold for the North   false alarms among stayers   recall\")\nfor threshold in (0.2, 0.3, 0.4, 0.5):\n    fa = (stayed[\"risk\"] >= threshold).mean()\n    rec = (churned[\"risk\"] >= threshold).mean()\n    print(f\"{threshold:24.2f}   {fa:26.1%}   {rec:6.1%}\")", "note": "Raise the North's threshold step by step and watch both of its error rates."}], "output": "threshold for the North   false alarms among stayers   recall\n                    0.20                        22.0%    58.8%\n                    0.30                        15.0%    58.8%\n                    0.40                        11.0%    52.9%\n                    0.50                         6.0%    52.9%"}
```

To bring the North's false alarms down to the others', 6.2 to 9.2 per cent, the threshold has to go
up to about 0.5. On the way there the North's recall drops from 58.8 to 52.9 per cent, one customer
of 17, which again is too few to read.

It works on the number. It is still the weaker fix, for three reasons.

- **It treats the symptom.** The model still reads a slow rhythm as fading. Reuse it for another
  decision and the problem comes back, with nothing in the model to warn anybody.
- **It uses the group explicitly.** Two customers with the same risk are treated differently because
  of where they live. That can be defended, as a correction for a known flaw, but it has to be
  defended, in writing, and in some kinds of decision and some countries it is not allowed.
- **It needs the group to be known and large enough to tune.** A threshold fitted on 100 loyal
  customers is itself a noisy number, and for a group nobody has thought to check, there is no
  threshold at all.

A per-group threshold is a reasonable stopgap when the cause cannot be reached in time, applied
openly while the real fix is built. As a permanent answer it hides a flaw that the next use of the
model will find again.
