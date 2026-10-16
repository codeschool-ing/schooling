---
title: Who changed
version: 1
---

A card for everybody hides a change in somebody. **Split the same card by the groups the business
recognises**, home shop and age here, and compare what the model said with what happened in each.
Save this as `segments.py`:

```python
"""segments.py: one night's report card, split by home shop and age, to find who changed.

    python segments.py 2026-03-29
"""
import datetime as dt
import sqlite3
import sys

import pandas as pd

from featurestore import STORE
from project import LABEL_DAYS, ROOT, SHOP

night = sys.argv[1]
closes = (dt.date.fromisoformat(night) + dt.timedelta(days=LABEL_DAYS)).isoformat()
with sqlite3.connect(SHOP) as db:
    bought = pd.read_sql_query("SELECT DISTINCT member_id FROM purchases "
                               "WHERE day > ? AND day <= ?", db, params=(night, closes))
with sqlite3.connect(ROOT / "scores.db") as db:
    scores = pd.read_sql_query("SELECT * FROM lapse_scores WHERE cutoff = ?", db, params=(night,))
with sqlite3.connect(STORE) as db:
    who = pd.read_sql_query("SELECT member_id, home_shop, age_band FROM offline WHERE as_of = ?",
                            db, params=(night,))

rows = scores.merge(who, on="member_id")
rows["lapsed"] = (~rows["member_id"].isin(bought["member_id"])).astype(int)
rows["age"] = rows["age_band"].where(rows["age_band"].isin(["18-24", "25-34"]), "35+")
table = rows.groupby(["home_shop", "age"]).agg(members=("member_id", "size"),
                                               said=("p_lapse", "mean"),
                                               happened=("lapsed", "mean"))
table["gap"] = table["happened"] - table["said"]
print(table.round(3).sort_values("gap", ascending=False).to_string())
```

Members of 35 and over are one group, because the young bands are where a change in habits shows
first and the older bands are each too small in some shops. `gap` is what happened minus what was
said: positive where more members left than the model expected. The six largest:

```
ana@dev:~/ml$ python segments.py 2026-03-29 | head -n 8
                 members   said  happened    gap
home_shop age                                   
Pinheiros 25-34      130  0.182     0.508  0.325
Paulista  25-34      162  0.160     0.432  0.272
          18-24       74  0.208     0.473  0.265
Cambuí    18-24       34  0.280     0.382  0.102
Batel     25-34       66  0.207     0.273  0.066
          18-24       42  0.351     0.405  0.054
```

**Three groups stand out, and they share two things**: they are young, and they belong to the two
shops in São Paulo. Members aged 25 to 34 at Pinheiros were given an average of 18% and half of them
left. Everywhere else the gaps are a few points either way, which is noise for groups of this size.

That is concept drift with an address. The inputs of these members look as they always did, so no
input check could have found it; their outcomes changed, from April, and the rival subscription that
launched in São Paulo on 1 April is the obvious suspect. A data team would take this table to
marketing, who would know about the rival before any model did. **The table does not explain the
change; it says where to ask.**
