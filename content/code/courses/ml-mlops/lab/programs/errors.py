"""errors.py: three ways to measure how far off the spend regression is."""
from sklearn.dummy import DummyRegressor
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, median_absolute_error, root_mean_squared_error

import features
from regress import examples

train, test = examples("2025-09-30"), examples("2025-11-30")
y = test["spend_next_90d"] / 100                      # in reais from here on

for name, model in (("average", DummyRegressor()), ("regression", LinearRegression())):
    model.fit(train[features.NUMERIC], train["spend_next_90d"] / 100)
    guess = model.predict(test[features.NUMERIC])
    print(f"{name:10}  MAE R$ {mean_absolute_error(y, guess):6.2f}   "
          f"RMSE R$ {root_mean_squared_error(y, guess):6.2f}   "
          f"median R$ {median_absolute_error(y, guess):6.2f}")

print(f"largest spends: {', '.join(f'R$ {v:.2f}' for v in y.nlargest(3))}")
