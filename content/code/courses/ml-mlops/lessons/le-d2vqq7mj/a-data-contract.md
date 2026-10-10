---
title: A data contract the training set must pass
version: 1
---

A model trained on broken rows is a broken model with a good score, so **the training set is checked
before anything learns from it**, by a step whose only job is to say yes or no. The checks are a
**data contract**: what the modeller and the platform agreed the rows would look like. Save this as
`validate.py`:

```python
"""validate.py: the checks a training set must pass before anything learns from it.

    python validate.py data/train.csv
"""
import sys

import pandas as pd

import features
from project import ROOT

path = ROOT / sys.argv[1]
rows = pd.read_csv(path)
problems = []

expected = ["cutoff", "member_id", *features.CATEGORICAL, *features.NUMERIC, "lapsed"]
if sorted(rows.columns) != sorted(expected):
    problems.append(f"columns differ: {sorted(set(rows.columns) ^ set(expected))}")
if rows["member_id"].duplicated().any():
    problems.append(f"{rows['member_id'].duplicated().sum()} members appear twice")
if rows["cutoff"].nunique() != 1:
    problems.append("more than one cutoff in one file")
for column in features.NUMERIC:
    if rows[column].isna().any():
        problems.append(f"{column} has {rows[column].isna().sum()} empty values")
    if (rows[column] < 0).any():
        problems.append(f"{column} is negative for {(rows[column] < 0).sum()} members")
if not rows["lapsed"].isin([0, 1]).all():
    problems.append("lapsed holds something other than 0 and 1")
if not 0.05 <= rows["lapsed"].mean() <= 0.35:
    problems.append(f"{rows['lapsed'].mean():.1%} lapsed, outside the 5% to 35% ever seen")
if len(rows) < 1000:
    problems.append(f"only {len(rows)} rows")

if problems:
    print(f"{sys.argv[1]}: REFUSED")
    for p in problems:
        print("  -", p)
    sys.exit(1)
print(f"{sys.argv[1]}: {len(rows)} rows, every check passed")
```

Each check is one sentence a person agreed to:

| check | what it would have caught |
| --- | --- |
| exactly these columns | a feature renamed upstream, or a new one nobody asked for |
| one row per member | a join that fanned out, doubling some members |
| one cutoff per file | two months' files concatenated by mistake |
| no empty or negative numbers | lesson 3's summary-table recency, which went negative |
| the label is 0 or 1 | a label column that arrived as text |
| between 5% and 35% lapsed | unfinished labels, which reached 65.5% in lesson 3 |
| at least 1,000 rows | a source table that loaded half a day |

**The label range is the one that needs a person.** 5% to 35% is wider than anything this shop has
shown; it is there to catch a broken label, not a real change in members, and lesson 10 is about
telling those two apart.

```
ana@dev:~/ml$ python validate.py data/train.csv
data/train.csv: 2863 rows, every check passed
ana@dev:~/ml$ python validate.py data/test.csv
data/test.csv: 3130 rows, every check passed
ana@dev:~/ml$ python -c "import pandas as pd; r = pd.read_csv('data/train.csv'); r.loc[:9, 'recency_days'] -= 200; pd.concat([r, r.head(5)]).to_csv('data/broken.csv', index=False)"
ana@dev:~/ml$ python validate.py data/broken.csv; echo "exit status $?"
data/broken.csv: REFUSED
  - 5 members appear twice
  - recency_days is negative for 15 members
exit status 1
```

The two real files pass. The third is made broken on purpose by the one-line program before it:
ten members' recency pushed 200 days into the negative, and five rows copied onto the end. The
count says 15 negative because the five copies were of broken rows. **The step refuses it and says
each reason**, and its exit status is 1, which is what will stop a
pipeline before training.

A check that fails should be read before it is loosened. The commonest wrong fix for a failing
contract is to widen the range until the rows pass; the right one starts by finding out what
changed in the data.
