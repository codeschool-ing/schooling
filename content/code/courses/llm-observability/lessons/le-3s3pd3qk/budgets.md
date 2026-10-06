---
title: Budgets in the code
version: 1
---

A report says what was spent. A budget says what may be spent, and the useful ones are checked by the
application, not read by a person at the end of the month. Two kinds work for a system like this.

**A budget per feature per day** says how much the product is willing to spend on each thing it does.
Crossing it is not an error; it is a signal that usage or cost per request moved, and somebody should
look. **A cap per user per day** protects against one account, or one script, spending what everybody
else together would. Crossing it is a decision the application makes on the spot: slow down, use a
cheaper model, or refuse until tomorrow.

The lab's budgets are a file, and `budget.py` holds the week against them:

```python
"""budget.py: each day's spend per feature against a daily budget, and the users over a daily cap."""
import json
from collections import defaultdict
from decimal import Decimal

import costs

BUDGET = {k: Decimal(v) for k, v in json.load(open("budgets.json"))["daily"].items()}
CAP = Decimal(json.load(open("budgets.json"))["per_user_daily"])
day_feature, day_user = defaultdict(Decimal), defaultdict(Decimal)
for r in costs.requests():
    day = r["at"].strftime("%a %d")
    day_feature[day, r["feature"]] += r["cost"]
    day_user[day, r["user"]] += r["cost"]
print(f"{'day':7}" + "".join(f"{f:>16}" for f in BUDGET))
for day in dict.fromkeys(d for d, _ in day_feature):
    cells = []
    for f, b in BUDGET.items():
        spent = day_feature[day, f]
        cells.append(f"{spent:.4f}{' OVER' if spent > b else '     '}".rjust(16))
    print(f"{day:7}" + "".join(cells))
over = sorted((v, d, u) for (d, u), v in day_user.items() if v > CAP)
print(f"users over {CAP} a day: {len(over)}")
for v, d, u in over[-3:]:
    print(f"  {d}  {u}  {v:.4f}")
```

```
ana@lab:~/obs$ cat budgets.json
{"daily": {"help": "0.10", "order": "0.04", "summary": "0.012"}, "per_user_daily": "0.005"}
ana@lab:~/obs$ python budget.py
day                help           order         summary
Mon 28      0.0986          0.0434 OVER     0.0121 OVER
Tue 29      0.1130 OVER     0.0383          0.0126 OVER
Wed 30      0.1220 OVER     0.0322          0.0116     
Thu 01      0.0827          0.0334          0.0070     
Fri 02      0.0751          0.0200          0.0067     
Sat 03      0.0423          0.0094          0.0048     
Sun 04      0.0439          0.0083          0.0054     
users over 0.005 a day: 8
  Mon 28  29732abf5563ccec  0.0060
  Tue 29  adc7eb33a816d390  0.0066
  Tue 29  3f5e7afb6e2effd3  0.0074
```

The budgets were set by looking at the week, which is how a first budget is usually set, and that is
why the overruns cluster where the week was busiest. `help` crossed its 0.10 on Tuesday and
Wednesday, `order` its 0.04 on Monday, and `summary` its 0.012 on Monday and Tuesday. From
Thursday on nothing comes near, which in this week is the price cut and then the release, not
restraint.

Eight times in the week a user crossed half a cent in a day, none of them by much: the largest was
0.0074. None is alarming, and that is what a cap is for. It costs nothing until the day it matters.

## Where the check goes

`budget.py` reads the spans after the fact, which is right for a daily report and too late for a
cap. A cap is checked **before the call**: keep a running total per user for the day, in the same
store the application already uses for sessions, add each request's cost as it completes, and look
at the total before starting the next. The spans stay the record; the running total is the brake.

And the provider's own limits sit behind both. `ai-models` lesson 21 sets spend limits and alerts in
the providers' consoles. Those are the last line, the one that holds when the application's own check
has a bug; they should never be the first.
