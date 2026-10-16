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
