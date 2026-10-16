---
title: Rolling out a new version without betting everyone on it
version: 1
---

A new version can pass every offline test and still behave differently on real requests. **The safe
way to find out is to give it a small, fixed share of the traffic and compare**, which is called a
**canary**, after the birds once carried into mines as an early warning. Lesson 1's reinforcement
learning met the same idea: trying a new option costs something, so it is tried on a few.

Two rules make a canary trustworthy. **The split is decided by the member, not by chance on each
request**, so one person does not get version 1 at ten past and version 2 at quarter past. And
**nobody chooses who is in it**, or the canary group differs from the rest for reasons that have
nothing to do with the model. A hash of the member's id gives both. This program splits tonight's
members the way a service would, scores the canary with version 2 and everybody else with version 1,
and compares the two groups. Save it as `canary.py`:

```python
"""canary.py: send one member in ten to a new version, and compare the two groups."""
import sqlite3
import zlib

import mlflow
import pandas as pd

from featurestore import STORE
from model import COLUMNS
from project import ROOT

CANARY_PERCENT = 10


def arm(member_id):
    """The same member always lands in the same group, and nobody chooses which."""
    return "canary" if zlib.crc32(str(member_id).encode()) % 100 < CANARY_PERCENT else "stable"


mlflow.set_tracking_uri(f"sqlite:///{ROOT / 'mlflow.db'}")
versions = {"stable": mlflow.sklearn.load_model("models:/lapse/1"),
            "canary": mlflow.sklearn.load_model("models:/lapse/2")}

with sqlite3.connect(STORE) as db:
    rows = pd.read_sql_query("SELECT * FROM offline WHERE as_of = '2026-02-28'", db)
rows["arm"] = rows["member_id"].map(arm)
for name, model in versions.items():
    group = rows["arm"] == name
    rows.loc[group, "p_lapse"] = model.predict_proba(rows.loc[group, COLUMNS])[:, 1]

summary = rows.groupby("arm").agg(members=("member_id", "size"), mean_p=("p_lapse", "mean"),
                                  over_0_2=("p_lapse", lambda p: (p > 0.2).mean()))
print(summary.round(3).to_string())
```

`zlib.crc32` turns the id into a number that looks random and is always the same for the same id;
its last two digits decide the group.

```
ana@dev:~/ml$ python canary.py
        members  mean_p  over_0_2
arm                              
canary      335   0.421     0.869
stable     3020   0.175     0.243
```

335 members went to the canary, close to the 10% asked for, with no list kept anywhere. **And the
canary caught version 2 at once**: its members were given an average probability of 0.421 against
0.175, and 86.9% of them crossed 0.2, lesson 4's best threshold, against 24.3% of the others. Those
two groups are drawn from the same members by a hash, so the difference is the model's.

Nobody has to wait 90 days for labels to see this. **What a canary watches first is what the model
says, not whether it was right**, and a version whose outputs look nothing like the stable
version's is stopped before it reaches the other 90%. Lesson 9 turns that comparison into a check
that runs every night, and lesson 10 is about the rarer case where the new version is the one
telling the truth.

A **shadow** deployment is the cautious cousin: the new version scores every request too, but its
answers are only logged, never used. It costs twice the computation and risks nothing.
