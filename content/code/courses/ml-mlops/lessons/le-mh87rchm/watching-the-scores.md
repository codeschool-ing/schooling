---
title: Watching what the model says
version: 1
---

The third question, what is the model saying, needs no outcomes. **It compares tonight with the
recent past**: if the same model, fed the same kind of members, suddenly says something different,
either the members changed or something between the shop and the model broke. Either way somebody
should look before marketing sends the list.

The batch of lesson 8 has scored one night. A comparison needs a past, so score the four Sundays
before it from the feature store's weekly snapshots, as the job would have if it had been running:

```
ana@dev:~/ml$ for night in 2026-02-01 2026-02-08 2026-02-15 2026-02-22; do python score_batch.py $night; done
3291 members scored as of 2026-02-01 by lapse version 1; 6646 rows in lapse_scores
3300 members scored as of 2026-02-08 by lapse version 1; 9946 rows in lapse_scores
3316 members scored as of 2026-02-15 by lapse version 1; 13262 rows in lapse_scores
3341 members scored as of 2026-02-22 by lapse version 1; 16603 rows in lapse_scores
```

Then the watch. It reads the scores and the inputs of the 28 days before the night, and compares
the night against them. Save it as `watch.py`:

```python
"""watch.py: one night's inputs and scores against the four weeks before it.

    python watch.py 2026-02-28      # exits 1 if anything is out of line
"""
import sqlite3
import sys

import pandas as pd

import features
from featurestore import STORE
from project import ROOT

night = sys.argv[1]
WINDOW = (night, night)   # the reference is every snapshot in the 28 days before the night
with sqlite3.connect(STORE) as db:
    inputs = pd.read_sql_query("SELECT * FROM offline WHERE as_of <= ? "
                               "AND as_of >= date(?, '-28 days')", db, params=WINDOW)
with sqlite3.connect(ROOT / "scores.db") as db:
    scores = pd.read_sql_query("SELECT * FROM lapse_scores WHERE cutoff <= ? "
                               "AND cutoff >= date(?, '-28 days')", db, params=WINDOW)

alarms = []


def check(name, before, tonight, low, high):
    """Alarm when tonight is outside low..high times what the reference saw."""
    ok = before * low <= tonight <= before * high
    print(f"{'ok   ' if ok else 'ALARM'} {name:<22} before {before:>9.3f}   tonight {tonight:>9.3f}")
    if not ok:
        alarms.append(name)


ref, now = scores[scores["cutoff"] < night], scores[scores["cutoff"] == night]
if now.empty:
    sys.exit(f"ALARM no scores for {night}: the batch did not run")
check("members scored", ref.groupby("cutoff").size().mean(), len(now), 0.9, 1.1)
check("mean p_lapse", ref["p_lapse"].mean(), now["p_lapse"].mean(), 0.8, 1.25)
check("share over 0.2", (ref["p_lapse"] > 0.2).mean(), (now["p_lapse"] > 0.2).mean(), 0.8, 1.25)

ref, now = inputs[inputs["as_of"] < night], inputs[inputs["as_of"] == night]
for column in features.NUMERIC:
    check(column + " median", ref[column].median(), now[column].median(), 0.5, 2)
for column in features.CATEGORICAL:
    new = set(now[column].dropna()) - set(ref[column].dropna())
    if new:
        print(f"ALARM {column}: values never seen before: {sorted(new)}")
        alarms.append(column)

sys.exit(f"{len(alarms)} alarm(s) for {night}" if alarms else 0)
```

It asks three things of the scores and two of the inputs:

- **how many members were scored**, against the average night before: a join that silently lost a
  shop shows up here first;
- **the mean probability and the share over 0.2**, the threshold marketing acts on: a model fed
  broken inputs rarely fails loudly, it drifts to saying everybody or nobody;
- **the median of every numeric input**, allowed to halve or double before it raises an alarm,
  because the median shrugs off a few odd members and moves only when most of them do;
- **any category never seen before**, a new shop or a misspelt channel, which the encoder from lesson
  2 turns into zeros without a word.

The bounds, 10% for the count, 25% for the scores, half and double for the inputs, are judgments,
not laws, and section 10 comes back to them. **And the program exits with status 1 when anything is
out of line**, which is what lets a scheduler stop the chain and tell somebody. On tonight:

```
ana@dev:~/ml$ python watch.py 2026-02-28; echo "exit status $?"
ok    members scored         before  3312.000   tonight  3355.000
ok    mean p_lapse           before     0.174   tonight     0.174
ok    share over 0.2         before     0.241   tonight     0.243
ok    tenure_days median     before   430.000   tonight   437.000
ok    recency_days median    before    20.000   tonight    20.000
ok    visits_180d median     before     6.000   tonight     5.000
ok    spend_180d median      before 52910.000   tonight 51910.000
ok    basket_avg median      before  9485.000   tonight  9486.000
ok    online_share median    before     0.250   tonight     0.231
ok    shops_180d median      before     2.000   tonight     2.000
exit status 0
```

Ten lines, all `ok`, and an exit status of 0. Tonight looks like the four weeks before it, which is
what a normal night should look like, and all the watch can say on its own: it knows the model is
saying what it usually says, not that what it usually says is right.
