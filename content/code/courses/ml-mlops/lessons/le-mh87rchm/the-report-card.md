---
title: The report card, and why it is late
version: 1
---

The fourth question, was the model right, can only be answered about a night whose outcomes are in.
**A report card joins the scores stored for a night with what each member then did**: bought again
within 90 days, or not. It is the same arithmetic as lesson 5's `evaluate.py`, applied to scores
that were actually produced rather than to a test set. Save it as `report_card.py`:

```python
"""report_card.py: one night's stored scores against what the members then did.

    python report_card.py 2025-11-30
"""
import datetime as dt
import json
import sqlite3
import sys

import pandas as pd
from sklearn.metrics import average_precision_score, roc_auc_score

from project import LABEL_DAYS, ROOT, SHOP

night = sys.argv[1]
closes = (dt.date.fromisoformat(night) + dt.timedelta(days=LABEL_DAYS)).isoformat()
with sqlite3.connect(SHOP) as db:
    last_day = db.execute("SELECT max(day) FROM purchases").fetchone()[0]
    if closes > last_day:
        sys.exit(f"not yet: the outcomes of {night} close on {closes}, "
                 f"and the data ends on {last_day}")
    bought = pd.read_sql_query("SELECT DISTINCT member_id FROM purchases "
                               "WHERE day > ? AND day <= ?", db, params=(night, closes))
with sqlite3.connect(ROOT / "scores.db") as db:
    scores = pd.read_sql_query("SELECT * FROM lapse_scores WHERE cutoff = ?", db, params=(night,))

scores["lapsed"] = (~scores["member_id"].isin(bought["member_id"])).astype(int)
p, lapsed = scores["p_lapse"], scores["lapsed"]
print(json.dumps({
    "night": night,
    "model_version": ", ".join(sorted(scores["model_version"].unique())),
    "members": len(scores),
    "lapsed": int(lapsed.sum()),
    "roc_auc": round(roc_auc_score(lapsed, p), 3),
    "average_precision": round(average_precision_score(lapsed, p), 3),
    "lapsed_in_top_300": int(lapsed[p.nlargest(300).index].sum()),
    "said": round(p.mean(), 3),
    "happened": round(lapsed.mean(), 3),
}, indent=2))
```

The outcome is computed here from the purchases, with the same rule as `features.py`: lapsed if
nothing was bought in the 90 days after the night. **And the program refuses a night whose 90 days
have not passed**, for the reason lesson 3 refused to train on unfinished labels: a member with no
purchase yet may simply not have come back yet.

The champion's test set was the night of 30 November 2025, so score that night with the batch, and
ask for both report cards:

```
ana@dev:~/ml$ python score_batch.py 2025-11-30
3130 members scored as of 2025-11-30 by lapse version 1; 19733 rows in lapse_scores
ana@dev:~/ml$ python report_card.py 2025-11-30
{
  "night": "2025-11-30",
  "model_version": "1",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.793,
  "average_precision": 0.522,
  "lapsed_in_top_300": 190,
  "said": 0.177,
  "happened": 0.169
}
ana@dev:~/ml$ python report_card.py 2026-02-28
not yet: the outcomes of 2026-02-28 close on 2026-05-29, and the data ends on 2026-02-28
```

**The first card is the test, reproduced**: an AUC of 0.793, average precision 0.522, 190 lapsed
members among the top 300, said 0.177 against 0.169 that happened. Those are lesson 5's numbers to
the last digit. That is no discovery about the model, since the night is the one it was tested on,
but it is a check of the card itself: a monitor that disagrees with a number you already trust has
a bug, and finding it now is cheaper than finding it in May.

**The second card refuses.** The scores of 28 February close on 29 May 2026, and the shop's data
ends on the night they were made. Every night's card is due 90 days after the night, and until then
the watch of section 06 is all there is. Lesson 10 moves the calendar forward to May and reads the
card that matters.
