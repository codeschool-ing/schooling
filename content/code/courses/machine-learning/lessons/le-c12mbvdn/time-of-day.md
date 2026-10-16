---
title: The hour of the day
version: 1
---

Lesson 5 turned the delivery hour into a flag, `rush`, and said the choice belonged to this lesson.
There are four ways to give a model an hour, and each says something different about what an hour is:

- **a number**, 8 to 20: later is slower, by the same amount each hour;
- **a point on a clock**, the sine and cosine of the hour as an angle: 23:00 is next to midnight, which
  is the standard advice for anything that wraps round;
- **one column per hour**, one-hot: every hour is its own thing, and the model learns each one;
- **a rush-hour flag**, 1 at 11, 12, 17, 18 and 19: somebody who knows the city says which hours
  are busy.

They can be compared directly. Save this as `hours.py`; it fits lesson 5's line with the hour given
each way, and once without it:

```python
# hours.py
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]

def table(rows, hour_as):
    out = rows[["distance_km", "items", "rain", "driver_months"]].copy()
    if hour_as == "a number":
        out["hour"] = rows["hour"]
    elif hour_as == "a point on a clock":
        out["hour_sin"] = np.sin(2 * np.pi * rows["hour"] / 24)
        out["hour_cos"] = np.cos(2 * np.pi * rows["hour"] / 24)
    elif hour_as == "one column per hour":
        hours = pd.get_dummies(rows["hour"], prefix="hour", dtype=float)
        out = pd.concat([out, hours.reindex(columns=[f"hour_{h}" for h in range(8, 21)],
                                            fill_value=0)], axis=1)
    elif hour_as == "a rush-hour flag":
        out["rush"] = rows["hour"].isin([11, 12, 17, 18, 19]).astype(int)
    return out

print("the hour as            columns   off by")
for hour_as in ["left out", "a number", "a point on a clock", "one column per hour",
                "a rush-hour flag"]:
    line = LinearRegression().fit(table(train, hour_as), train["minutes"])
    error = (test["minutes"] - line.predict(table(test, hour_as))).abs().mean()
    print(f"{hour_as:21} {table(train, hour_as).shape[1]:8}   {error:5.2f} min")
```

`reindex` makes sure the hour columns are the same thirteen, in the same order, on both sets, which is
the job `OneHotEncoder` would do by itself; here it shows what that job is.

```
ana@lab:~/ml$ python hours.py
the hour as            columns   off by
left out                     4    7.22 min
a number                     5    7.06 min
a point on a clock           6    7.07 min
one column per hour         17    5.88 min
a rush-hour flag             5    5.87 min
```

**The clock did no better than the plain number**, 7.07 minutes against 7.06, and both barely beat
leaving the hour out. The sine and cosine are right when the effect rises and falls smoothly around the
day, as temperature does. Rush hours are two humps, at lunch and after work, and a smooth wave through
the day cannot draw two humps. Deliveries also run from 8 to 20, so the wrap from 23:00 to midnight,
the reason for the clock, never happens.

**One column per hour finds the humps by itself**, 5.88 minutes, with thirteen columns and no knowledge.
**The flag gets the same, 5.87, with one column**, because somebody who knew the city wrote it down.
On six thousand deliveries the two are equal. On a few hundred, the thirteen hourly weights would each
be learned from a few dozen rows, and the flag would win.

The same thinking applies to dates. A date as a number says *later is different*, and every date the model
will be asked about is later than all the dates it learned from, so the weight it learned is a guess
about a future it never saw. Pieces of a date are often
better: the day of the week, whether it is a holiday, how many days until payday. And a date is where
the future most easily leaks in. **A feature computed from a date must use only what was known on that
date.**
