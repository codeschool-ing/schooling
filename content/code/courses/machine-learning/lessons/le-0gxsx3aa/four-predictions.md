---
title: Four predictions to judge
version: 1
---

Lessons 2, 5 and 8 each predicted how long a delivery takes, and each judged its prediction by one
number: how many minutes off, on average. This lesson is about that number and the three others
people reach for, and the way to see what each one rewards is to put several models side by side
and watch the metrics disagree.

The first program fits four of them on the deliveries before October and saves what each predicts
for the test months, so every later program in the lesson reads the same predictions:

- **`by_hour`**, the best of lesson 2's baselines: the median delivery time at that hour;
- **`line`**, lesson 5's linear regression, fitted by squared error, which aims at the **mean**;
- **`boost_squared`**, gradient boosting from lesson 8 with its default loss, also squared error;
- **`boost_absolute`**, the same model with `loss="absolute_error"`, which aims at the **median**.

Save this as `predictions.py`:

```python
# predictions.py
import pandas as pd
from sklearn.ensemble import HistGradientBoostingRegressor
from sklearn.linear_model import LinearRegression

deliveries = pd.read_csv("data/deliveries.csv", parse_dates=["date"])
deliveries["rush"] = deliveries["hour"].isin([11, 12, 17, 18, 19]).astype(int)
train = deliveries[deliveries["date"] < "2025-10-01"]
test = deliveries[deliveries["date"] >= "2025-10-01"].copy()
features = ["distance_km", "items", "rush", "rain", "driver_months"]

test["by_hour"] = test["hour"].map(train.groupby("hour")["minutes"].median())
test["line"] = LinearRegression().fit(train[features], train["minutes"]).predict(test[features])
for name, loss in [("boost_squared", "squared_error"), ("boost_absolute", "absolute_error")]:
    model = HistGradientBoostingRegressor(loss=loss, random_state=0)
    test[name] = model.fit(train[features], train["minutes"]).predict(test[features])
columns = ["delivery_id", "minutes", "by_hour", "line", "boost_squared", "boost_absolute"]
test[columns].round(2).to_csv("predictions.csv", index=False)
print(f"{len(test):,} test deliveries, four predictions each; saved predictions.csv")
```

```
ana@lab:~/ml$ python predictions.py
1,540 test deliveries, four predictions each; saved predictions.csv
```

Then the four metrics this lesson is named after, all from `sklearn.metrics`. Save this as
`errors.py`:

```python
# errors.py
import pandas as pd
from sklearn.metrics import (mean_absolute_error, mean_absolute_percentage_error,
                             mean_squared_error, r2_score)

predictions = pd.read_csv("predictions.csv")
truth = predictions["minutes"]
print("model              MAE    RMSE    MAPE      R²")
for model in ["by_hour", "line", "boost_squared", "boost_absolute"]:
    guess = predictions[model]
    print(f"{model:15} {mean_absolute_error(truth, guess):6.2f} "
          f"{mean_squared_error(truth, guess) ** 0.5:7.2f} "
          f"{mean_absolute_percentage_error(truth, guess):7.1%} {r2_score(truth, guess):7.3f}")
```

```
ana@lab:~/ml$ python errors.py
model              MAE    RMSE    MAPE      R²
by_hour          10.89   18.16   22.8%   0.021
line              5.87   14.25   11.2%   0.397
boost_squared     6.23   14.46   12.2%   0.379
boost_absolute    5.02   14.43    8.7%   0.382
```

Read it by column and the verdicts differ. **MAE and MAPE put `boost_absolute` clearly first.** RMSE
puts the line first, and the three models within a quarter of a minute of each other. R² agrees
with RMSE and makes all three look mediocre, explaining under 40% of something. One table, three
stories about which model is best.

None of the four is wrong. Each one measures a different kind of mistake, and the next four
sections take them one at a time. Then comes the question none of them answers, which for a
delivery promise is the one that matters: **whether the model is late or early**.
