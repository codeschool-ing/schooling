---
title: Late or early
version: 1
---

Every metric so far threw away the sign of the error. MAE takes the absolute value, RMSE and R²
square it, MAPE takes the absolute value again. **A delivery 10 minutes late and one 10 minutes
early count the same in all four.**

Lesson 1 said they do not cost the same. Feira em Casa wants to tell each customer when the box will
arrive, and the logistics team's view is plain: a box promised in 40 minutes that arrives in 30 bothers
nobody, and one that arrives in 50 produces a complaint. Suppose the app shows the model's prediction
as the promise. The question is then how often each model is late, and by how much. Save this as
`direction.py`:

```python
# direction.py
import pandas as pd

predictions = pd.read_csv("predictions.csv")
print("promise = prediction   average error   late   late by more than 10 min")
for model in ["line", "boost_squared", "boost_absolute"]:
    late_by = predictions["minutes"] - predictions[model]
    print(f"{model:20} {late_by.mean():+11.2f} min {(late_by > 0).mean():7.1%}"
          f" {(late_by > 10).mean():12.1%}")
```

The **average error** keeps the sign, and it has a name: the **bias**. Positive means the deliveries
took longer than predicted.

```
ana@lab:~/ml$ python direction.py
promise = prediction   average error   late   late by more than 10 min
line                       +0.20 min   26.6%         3.8%
boost_squared              +0.22 min   33.3%         4.0%
boost_absolute             +2.89 min   50.5%         5.0%
```

The model with the best MAE is **late on half its promises**, 50.5%. That is not a defect: it predicts
the median, and the median is by definition the time half of the deliveries exceed. It is exactly
what was asked for, and exactly wrong for a promise. Its bias is nearly three minutes late, because
the deliveries that run over run over by more than the early ones run under.

The line has almost no bias, +0.20 minutes, and is late only 26.6% of the time. It aims at the mean,
and the mean sits above the median here, so as a promise it is accidentally cautious. That is luck,
not design. On a target whose tail ran the other way it would be late more often than the median.

So a regression model needs **one more number reported beside the error: the direction of the
error**, as a bias and as a share of cases on the expensive side. Without it, the model with the best
MAE would have shipped as the delivery promise, and the complaints would have started on the first
day. The next section asks for the side directly.
