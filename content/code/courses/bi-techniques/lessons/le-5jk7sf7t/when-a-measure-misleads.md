---
title: When a measure misleads
version: 1
---

Each of the three measures has a way of saying something false, and each failure has a recognisable
shape.

## MAPE punishes the same miss more when the actual is low

```schooling-example
{"language": "python", "file": "mape_trap.py", "parts": [{"code": "import numpy as np\n\nprint(\"the same miss of 50 orders, against two actual values\")\nfor actual, forecast in [(150, 100), (50, 100)]:\n    print(f\"  actual {actual:3}, forecast {forecast}: error {abs(forecast - actual)}, \"\n          f\"{abs(forecast - actual) / actual:.0%} of the actual\")", "note": "One forecast of 100, missing by 50 in each direction."}, {"code": "actual = np.array([3, 1, 0, 2])\nforecast = np.array([2, 2, 2, 2])\nwith np.errstate(divide=\"ignore\"):\n    print(\"\\nsmall counts:\", np.abs(forecast - actual) / actual)", "note": "Four days of a product that sells a handful a day, one of them none. `errstate` silences numpy's warning about dividing by zero, so the result itself is what prints."}], "output": "the same miss of 50 orders, against two actual values\n  actual 150, forecast 100: error 50, 33% of the actual\n  actual  50, forecast 100: error 50, 100% of the actual\n\nsmall counts: [0.33333333 1.                inf 0.        ]"}
```

**The same miss of 50 orders counts as 33 per cent when the week turned out busy and 100 per cent
when it turned out quiet.** So a model that forecasts low is penalised less, on average, than one
that forecasts high by the same amount, and choosing models by MAPE quietly favours the ones that
under-forecast. If under-forecasting means running out of ingredients, that is the wrong way to
lean.

## MAPE breaks on small numbers

The second half of the output shows the other problem. A day with one sale missed by one is a 100
per cent error; a day with none cannot be divided by at all, and numpy returns `inf`, infinity,
which then makes the average infinite. **MAPE is unusable on series with zeros or very small
counts**: one product in one small region, the hours of the night, a new store. Use MAE there, or
divide the total absolute error by the total actual, a measure often called **WAPE**, weighted
absolute percentage error, which only fails if everything is zero.

## RMSE and MAE are in the series' own units

An RMSE of 460 orders is good for a series of ten thousand a week and terrible for a series of five
hundred. **Neither can be compared across series of different sizes**, which is why MAPE, for all
its faults, survives: it is the only one of the three a manager can compare between Panela's
regions. When the regions are large enough to have no zeros, that is a legitimate use.

## Every measure can be gamed by choosing the test

A model that is measured on the weeks it was fitted on looks better than it is. A model measured on
a quiet stretch looks better than one measured over Christmas. **Fix the test period before looking
at the results**, use weeks the models never saw, and measure every candidate on the same weeks.
The next section takes that one step further.
