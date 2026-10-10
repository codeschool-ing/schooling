---
title: Reading the weights out loud
version: 1
---

The output of `linear.py` is a sentence waiting to be said. Each weight is **how many minutes the
prediction moves when that column goes up by one and every other column stays where it is**:

| column | weight | read out loud |
|---|---|---|
| intercept | 18.32 | a delivery of zero kilometres, zero items, outside rush hour, dry, by a brand-new driver would take about 18 minutes: the fixed part |
| `distance_km` | +2.60 | each kilometre adds about two and a half minutes |
| `items` | +0.37 | each item adds about twenty seconds; thirty items, eleven minutes |
| `rush` | +9.57 | a rush hour adds nearly ten minutes |
| `rain` | +11.23 | rain adds about eleven minutes |
| `driver_months` | −0.07 | each month of experience saves about four seconds |

**"Every other column stays where it is" is the part people drop**, and it changes the meaning.
The weight of rain is what rain adds *to a delivery of the same distance, at the same hour, with the
same driver*. If rainy days also happened to have longer routes, the plain difference between wet
and dry deliveries would mix the two, and the weight separates them. That separation is the most
useful thing a linear model does, and it holds only for the columns the model was given.

The intercept is a different kind of number. It is a prediction for a delivery with every column
at zero, which may not exist: nobody delivers zero kilometres. **Read it as the fixed part of the
line, not as a fact about any real delivery.**

## What the line cannot see

A linear model adds its terms up. It cannot say "rain costs more on a long trip than on a short
one", because rain's weight is one number whatever the distance. If that is how rain works, the
model has to be told, with a column that is the product of the two. Save this as
`interaction.py`:

```python
# interaction.py
import pandas as pd
from sklearn.linear_model import LinearRegression

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
deliveries["rush"] = deliveries["hour"].isin([11, 12, 17, 18, 19]).astype(int)
deliveries["rain_km"] = deliveries["rain"] * deliveries["distance_km"]
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"]

for features in [["distance_km", "items", "rush", "rain", "driver_months"],
                 ["distance_km", "items", "rush", "rain", "driver_months", "rain_km"]]:
    line = LinearRegression().fit(train[features], train["minutes"])
    error = (test["minutes"] - line.predict(test[features])).abs().mean()
    coefs = dict(zip(features, line.coef_.round(2)))
    print(f"MAE {error:.2f}  rain {coefs['rain']:+.2f}  km {coefs['distance_km']:+.2f}"
          + (f"  rain_km {coefs['rain_km']:+.2f}" if "rain_km" in coefs else ""))
```

```
ana@lab:~/ml$ python interaction.py
MAE 5.87  rain +11.23  km +2.60
MAE 5.71  rain +3.55  km +2.38  rain_km +1.30
```

With the product `rain_km` added, the error falls from 5.87 to 5.71, and the story changes: rain
now adds **3.55 minutes plus 1.30 for every kilometre**, so 5 minutes on a short trip and 16 on a
ten-kilometre one, where the first model said 11 for both. The new column is an **interaction**,
and a linear model only has the ones it is given. Lesson 7's trees find interactions by
themselves, which is one of the reasons they usually win, and one of the reasons they are harder to
read.

Two warnings about reading weights, both of which this lesson returns to:

- **A weight is not a cause.** Rain does not cause minutes in the way a lever does; the weight is
  the difference the data shows, holding fixed only what is in the model. Lesson 19 is about the
  gap between what a model uses and what makes things happen.
- **Weights are only comparable on the same scale.** +2.60 per kilometre and +0.37 per item cannot
  be compared, because a kilometre and an item are not the same amount of anything. Section 07 of
  this lesson scales the columns so they can be.
