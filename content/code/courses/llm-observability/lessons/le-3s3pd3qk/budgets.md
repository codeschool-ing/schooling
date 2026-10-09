---
title: Budgets in the code
version: 2
---

A report says what was spent. A budget says what may be spent, and the useful ones are checked by the
application, not read by a person at the end of the month. Two kinds work for a system like this.

**A budget per feature per day** says how much the product is willing to spend on each thing it does.
Crossing it is not an error; it is a signal that usage or cost per request moved, and somebody should
look. **A cap per user per day** protects against one account, or one script, spending what everybody
else together would. Crossing it is a decision the application makes on the spot: slow down, use a
cheaper model, or refuse until tomorrow.

The budgets are a file, and `budget.py` holds the week against them:

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

Save the budgets as `budgets.json`:

```json
{"daily": {"help": "0.020", "order": "0.008", "summary": "0.003"}, "per_user_daily": "0.002"}
```

```
ana@dev:~/obs$ python budget.py
day                help           order         summary
Mon 28      0.0183          0.0086 OVER     0.0038 OVER
Tue 29      0.0212 OVER     0.0073          0.0025     
Wed 30      0.0166          0.0068          0.0013     
Thu 01      0.0114          0.0054          0.0024     
Fri 02      0.0081          0.0044          0.0036 OVER
Sat 03      0.0073          0.0020          0.0016     
Sun 04      0.0067          0.0032          0.0007     
users over 0.002 a day: 3
  Tue 29  2b86d5011760317d  0.0026
  Wed 30  bfc965310daf2eda  0.0030
  Mon 28  91aa3bdfe71fb999  0.0032
```

The budgets were set by looking at the week, which is how a first budget is usually set, and that is
why the overruns cluster where the week was busiest. `help` crossed its 0.020 on Tuesday, `order` its
0.008 on Monday, and `summary` its 0.003 on Monday. From Wednesday on, `help` and `order` come
nowhere near, which in this week is the price cut and then the release, not restraint. **`summary`
crossed again on Friday**, after both, because neither touched it: a summary searches nothing, so the
floor cannot shorten its prompt, and the support team simply asked for more of them that day. A
budget per feature is what tells those two stories apart.

Three times in the week a user crossed a fifth of a cent in a day, none of them by much: the largest
was 0.0032. None is alarming, and that is what a cap is for. It costs nothing until the day it
matters.

## Where the check goes

`budget.py` reads the spans after the fact, which is right for a daily report and too late for a
cap. A cap is checked **before the call**: keep a running total per user for the day, in the same
store the application already uses for sessions, add each request's cost as it completes, and look
at the total before starting the next. The spans stay the record; the running total is the brake.

And the provider's own limits sit behind both. `ai-models` lesson 21 sets spend limits and alerts in
the providers' consoles. Those are the last line, the one that holds when the application's own check
has a bug; they should never be the first.
