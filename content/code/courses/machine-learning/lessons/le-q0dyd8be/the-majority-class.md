---
title: The constant that is right 94% of the time
version: 1
---

The cheapest model there is answers the same thing for every row. scikit-learn has one, called
`DummyClassifier`, and it exists for exactly this job: to be fitted, scored and beaten. With
`strategy="most_frequent"` it learns one fact from the training rows, which class is commoner, and
predicts that class forever. Save this as `dummy.py`:

```python
# dummy.py
from sklearn.dummy import DummyClassifier
from sklearn.metrics import accuracy_score

from feira import NUMERIC, by_time, load_churn, net_value

train, test = by_time(load_churn())
print(f"learn from {len(train):,} rows, test on {len(test):,}")

dummy = DummyClassifier(strategy="most_frequent").fit(train[NUMERIC], train["churned"])
said = dummy.predict(test[NUMERIC])
print("it always says:", sorted(set(said.tolist())))
print(f"accuracy: {accuracy_score(test['churned'], said):.3f}")
print(f"net value: R$ {net_value(test['churned'], said):,.0f}")
```

```
ana@lab:~/ml$ python dummy.py
learn from 38,628 rows, test on 24,257
it always says: [0]
accuracy: 0.939
net value: R$ 0
```

**93.9% accurate, and worth nothing.** It says 0, *stays*, for all 24,257 test rows. It is right
about everybody who stayed and wrong about every one of the people who left, and because leavers
are about one row in sixteen, being wrong about all of them costs only six points of accuracy.

That is the first lesson a baseline teaches, and it is about the metric rather than the model:
**on a rare class, accuracy measures how rare the class is.** Any model of this data will score
somewhere around 94% whether it is excellent or useless, so accuracy cannot tell those two apart.
Lesson 10 replaces it with measures that can; this lesson uses the net value, where the constant
scores exactly what it should, R$ 0, and a model has to earn anything above that.

The features passed to `fit` are ignored, as the name promises. They are there because every
scikit-learn model is called the same way, which is what lets a dummy stand in a comparison
beside a real model with no special case in the code.

## The constants for the other kinds of problem

`DummyClassifier` has other strategies, and each is the honest floor for a different question:

| strategy | predicts | the floor for |
|---|---|---|
| `most_frequent` | the commonest class | accuracy, and any count of correct answers |
| `prior` | the commonest class, and the class shares as probabilities | anything scored on probabilities (lesson 10) |
| `stratified` | a class drawn at random in the training proportions | a model that only guesses at the right rate |

`DummyRegressor` is the same idea for a quantity, predicting the mean or the median of the
training target. Section 08 of this lesson uses that idea on the deliveries.
