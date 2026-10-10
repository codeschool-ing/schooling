---
title: The first step: a dataset, or a refusal
version: 1
---

The first step turns the shop into examples for one cutoff and writes them to a file. It takes the
cutoff and the output as arguments, so nothing about the date is inside the code, and it
**refuses** a cutoff whose labels are not finished, which was lesson 3's fourth kind of leak. Save
it as `build_dataset.py`:

```python
"""build_dataset.py: the examples for one cutoff, refused if their labels are not finished.

    python build_dataset.py 2025-09-30 data/train.csv
"""
import datetime as dt
import sqlite3
import sys

import features
from project import LABEL_DAYS, ROOT, SHOP

cutoff, out = sys.argv[1], ROOT / sys.argv[2]

with sqlite3.connect(SHOP) as db:
    last_day = db.execute("SELECT max(day) FROM purchases").fetchone()[0]
closes = dt.date.fromisoformat(cutoff) + dt.timedelta(days=LABEL_DAYS)
if closes.isoformat() > last_day:
    sys.exit(f"refused: the labels for {cutoff} close on {closes}, "
             f"and the data ends on {last_day}")

rows = features.build(cutoff, SHOP)
rows.insert(0, "cutoff", cutoff)
out.parent.mkdir(exist_ok=True)
rows.to_csv(out, index=False)
print(f"{out.relative_to(ROOT)}: {len(rows)} members as of {cutoff}, "
      f"{rows['lapsed'].mean():.1%} lapsed")
```

`features.build` gets the database's full path from `project.py`, and the output path is resolved
against the project too. **The refusal is computed from the data, not from today's date**: the
labels for a cutoff close 90 days later, and the step compares that with the last day the purchases
table actually holds. A database loaded late is caught the same way as a cutoff chosen badly.

```
ana@dev:~/ml$ python build_dataset.py 2025-08-31 data/train.csv
data/train.csv: 2863 members as of 2025-08-31, 16.6% lapsed
ana@dev:~/ml$ python build_dataset.py 2025-11-30 data/test.csv
data/test.csv: 3130 members as of 2025-11-30, 16.9% lapsed
ana@dev:~/ml$ (cd /tmp && python ~/ml/build_dataset.py 2026-01-31 data/jan.csv); echo "exit status $?"
refused: the labels for 2026-01-31 close on 2026-05-01, and the data ends on 2026-02-28
exit status 1
ana@dev:~/ml$ ls data
test.csv
train.csv
```

The training cutoff is 31 August and the test cutoff 30 November, the honest gap of lesson 3
section 07: the newest training label closes the day before the test cutoff. The last command asks
for 31 January, from another directory altogether, and is refused with the reason, and **nothing
is written**: no half-labelled file is left behind for a later step to pick up.

`sys.exit` with a message prints it and ends the program with a failing status, which matters for
the step after the next one: a pipeline stops at the first step that fails, and it can only know
one has failed if the step says so in its exit status.
