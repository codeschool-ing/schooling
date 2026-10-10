---
title: Baselines for a quantity
version: 1
---

A regression has baselines too, and they work the same way: the constant first, then the rules a
person would write, all chosen on the training rows and scored on the test rows. The score here is
the simplest there is for a quantity, **how far off the guess is, on average, in the target's own
unit**. Lesson 12 calls it the MAE and sets it beside the others.

The data is `deliveries.csv`: one row per delivery in 2025, and the minutes it took. The last three
months are the test. Save this as `delivery_baselines.py`:

```python
# delivery_baselines.py
import pandas as pd

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]
print(f"learn from {len(train):,} deliveries, test on {len(test):,}")

per_km = (train["minutes"] / train["distance_km"]).median()
guesses = {
    "the mean of all deliveries": train["minutes"].mean(),
    "the median of all deliveries": train["minutes"].median(),
    "the median of the city": test["city"].map(train.groupby("city")["minutes"].median()),
    "the median minutes per km, times km": per_km * test["distance_km"],
    "the median by hour of day": test["hour"].map(train.groupby("hour")["minutes"].median()),
}
for name, guess in guesses.items():
    error = (test["minutes"] - guess).abs().mean()
    print(f"  {name:38} off by {error:5.1f} minutes on average")
```

```
ana@lab:~/ml$ python delivery_baselines.py
learn from 4,460 deliveries, test on 1,540
  the mean of all deliveries             off by  12.0 minutes on average
  the median of all deliveries           off by  11.6 minutes on average
  the median of the city                 off by  11.6 minutes on average
  the median minutes per km, times km    off by  17.7 minutes on average
  the median by hour of day              off by  10.9 minutes on average
```

Three things in five lines of output.

**The median beats the mean as a constant**, 11.6 minutes against 12.0. A few deliveries take an
hour or two longer than usual, a flat tyre or a wrong address, and they pull the mean up; the
median ignores them, and an average distance in minutes is exactly what the median minimises.

**Splitting by city buys nothing.** The cities differ less in delivery time than it seems they
should, and the rule a manager would reach for first adds a column and no accuracy.

**The most sensible-sounding rule is the worst.** "Minutes per kilometre, times kilometres" is how
anybody would estimate a trip, and it is off by 17.7 minutes, worse than ignoring the distance
altogether. A delivery has a fixed part, loading the van and finding the door, that does not grow
with distance; a rule with no room for it is wrong in a way that grows with every short trip.
Lesson 5 fits a line that has both parts, and its error is the number to set against **10.9
minutes**, the best of these.
