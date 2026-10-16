---
title: Three ways to measure a miss
version: 1
---

Every forecast error is one number per week: what was forecast minus what happened. **A measure of
forecast accuracy is a way of turning that column of errors into one number**, and the three in
everyday use make different choices about how.

| measure | the arithmetic | in what unit | what it emphasises |
|---|---|---|---|
| **MAE**, mean absolute error | average the errors after dropping their signs | orders | the typical miss |
| **RMSE**, root mean squared error | square the errors, average, take the square root | orders | the large misses |
| **MAPE**, mean absolute percentage error | divide each miss by what happened, then average | per cent | the miss relative to the size |

And one more that is not an accuracy measure but should always be printed beside them:

- **bias**, the average of the errors *with* their signs. A forecast whose errors average to zero
  is too high as often as too low. One with a large bias is wrong in the same direction week after
  week, which is the most fixable mistake a forecast can make.

All four on five weeks small enough to check by hand:

```schooling-example
{"language": "python", "file": "errors.py", "parts": [{"code": "actual = [8796, 8753, 8812, 8422, 8458]\nforecast = [8659, 8844, 8587, 8653, 8181]", "note": "Five weeks of early 2025 and the Holt-Winters forecasts of lesson 3 for them, typed in so the arithmetic is visible."}, {"code": "errors = [f - a for f, a in zip(forecast, actual)]", "note": "An error is forecast minus actual: positive means the forecast was too high."}, {"code": "mae = sum(abs(e) for e in errors) / len(errors)\nrmse = (sum(e * e for e in errors) / len(errors)) ** 0.5\nmape = sum(abs(e) / a for e, a in zip(errors, actual)) / len(errors) * 100\nbias = sum(errors) / len(errors)", "note": "The three measures and the bias, each one line of arithmetic."}, {"code": "print(\"errors:\", errors)\nprint(f\"MAE  {mae:7.1f} orders\")\nprint(f\"RMSE {rmse:7.1f} orders\")\nprint(f\"MAPE {mape:7.2f} %\")\nprint(f\"bias {bias:7.1f} orders\")"}], "output": "errors: [-137, 91, -225, 231, -277]\nMAE    192.2 orders\nRMSE   203.8 orders\nMAPE    2.23 %\nbias   -63.4 orders"}
```

The MAE of 192.2 says the typical week was missed by about two hundred orders. The RMSE is a little
larger, 203.8, because squaring gives the biggest miss, 277, more weight than the smallest, 91.
The MAPE says the misses were about 2.2 per cent of the weeks they missed. And the bias of
−63.4 says the forecast was slightly low on balance, though with five weeks that is a hint rather
than a finding.

**RMSE is never smaller than MAE**, and the gap between them is information. When every miss is
about the same size they are nearly equal; when one week is missed badly and the rest are close,
RMSE pulls away. The next section is a case where that gap changes which model wins.
