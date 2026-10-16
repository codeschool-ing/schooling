---
title: The monthly run
version: 1
---

Lesson 21 ended on a choice: the credit is a batch decision, made once a month for everybody, so the
model's working life is a program that runs on the first of each month. This lesson is that program
running from January to March 2026, and what happens around it: what can be checked on the day, what can
only be checked a month later, and what to do when the two disagree.

The monthly program is short, because lesson 21 did the work. It loads the saved model through
`stored.load`, so a machine on the wrong versions refuses to run, scores one month's snapshot, and writes
the chances to a file named after the month, with the model's name in every row. Save this as
`monthly.py`:

```python
# monthly.py
import sys
from pathlib import Path

import stored
from feira import CREDIT, KEPT, SAVED, load_churn

month = sys.argv[1]
model, card = stored.load("churn-2025-12")
rows = load_churn("data/churn_2026.csv")
rows = rows[rows["snapshot"] == month]
chance = model.predict_proba(rows)[:, 1]
scores = rows[["customer_id", "snapshot"]].assign(chance=chance.round(4), model=card["name"],
                                                  credit=chance >= CREDIT / (SAVED * KEPT))
Path("scores").mkdir(exist_ok=True)
scores.to_csv(f"scores/{month[:7]}.csv", index=False)
print(f"{month[:7]}: {len(scores):,} subscribers, mean chance {chance.mean():.3f}, "
      f"{scores['credit'].sum()} credits, from {card['name']}")
```

In a real deployment `churn_2026.csv` would be a fresh export each month and the program would run on a
schedule. Here the three months are already in the file, so three runs stand in for three firsts of the month. The model file is lesson 21's; if `models/churn-2025-12.joblib` is not there, run
`python save_model.py` first.

```
ana@lab:~/ml$ for month in 2026-01-01 2026-02-01 2026-03-01; do python monthly.py $month; done
2026-01: 4,226 subscribers, mean chance 0.061, 154 credits, from churn-2025-12
2026-02: 4,388 subscribers, mean chance 0.065, 173 credits, from churn-2025-12
2026-03: 4,540 subscribers, mean chance 0.065, 180 credits, from churn-2025-12
ana@lab:~/ml$ ls scores
2026-01.csv
2026-02.csv
2026-03.csv
ana@lab:~/ml$ head -3 scores/2026-03.csv
customer_id,snapshot,chance,model,credit
C00003,2026-03-01,0.01,churn-2025-12,False
C00005,2026-03-01,0.0135,churn-2025-12,False
```

The file each run writes is the record that matters: **who was scored, by which model, with what
chance, and whether they were sent the credit.** Without it there is nothing to compare when the answers
arrive. It is the batch version of lesson 21's `scores.jsonl`, and it is kept, not overwritten: next
month's run writes next month's file.

The three runs already say one thing worth noticing. The mean chance is 0.061, 0.065 and 0.065. The
training months ended with the months after the September price rise, when as many as 7.2% of
subscribers left each month, so a model fitted on them expects a high level. Whether January 2026 is
still like that, nobody knows on the first of January.
