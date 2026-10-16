---
title: Tabular data, and three models on one table
version: 1
---

Nineteen lessons have trained networks, and it would be easy to leave them believing that a network
is the strong model, the one to reach for when the problem matters. **On a table of rows and
columns, that belief does not survive a measurement.** This section makes the measurement, on real
data, with the models `machine-learning` taught standing beside a network from this course.

A table here means what it means in a spreadsheet or a database: one row per case, one column per
measured quantity, and each column meaning something on its own. Sales records, loan applications,
sensor readings, patient measurements. Most of the data a company holds looks like this, and most of
the models a company runs are trained on it.

The program below is the bench for this section and the next. It runs three models on the same
table: logistic regression, scikit-learn's `HistGradientBoostingClassifier`, which is the gradient
boosting `machine-learning` lesson 8 taught, and a dense network in PyTorch. Each is scored by
five-fold cross-validation, `machine-learning` lesson 3's method, and timed. It needs the `loop.py`
from lesson 9 beside it. Save it as `~/dl/bench.py`:

```schooling-example
{
  "language": "python",
  "file": "bench.py",
  "parts": [
    {
      "code": "\"\"\"bench: three models on one table, five folds each, accuracy and the time it took.\"\"\"\nimport time\n\nimport numpy as np\nimport torch\nimport torch.nn as nn\nfrom sklearn.ensemble import HistGradientBoostingClassifier\nfrom sklearn.linear_model import LogisticRegression\nfrom sklearn.model_selection import StratifiedKFold\nfrom sklearn.pipeline import make_pipeline\nfrom sklearn.preprocessing import StandardScaler\nfrom threadpoolctl import threadpool_limits\n\nimport loop\n\ntorch.set_num_threads(1)\nthreadpool_limits(1)",
      "note": "Every model gets one processor. PyTorch and scikit-learn would each spread work over all four, and how well a library does that is not what this program measures. `threadpoolctl` came in with scikit-learn, so nothing new is installed."
    },
    {
      "code": "class TorchMLP:\n    \"\"\"A dense network with scikit-learn's fit and predict, so it can sit in the same loop.\"\"\"\n\n    def __init__(self, steps=200):\n        self.steps = steps",
      "note": "scikit-learn's models answer to `fit` and `predict`. Giving the network the same two methods lets one loop treat all three alike."
    },
    {
      "code": "    def fit(self, X, y):\n        self.scale = StandardScaler().fit(X)\n        x = torch.tensor(self.scale.transform(X), dtype=torch.float32)\n        t = torch.tensor(y)\n        torch.manual_seed(0)\n        d, k = x.shape[1], int(y.max()) + 1\n        self.net = nn.Sequential(nn.Linear(d, 64), nn.ReLU(),\n                                 nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, k))",
      "note": "The columns are standardised on the training fold only, as lesson 8 asked of a network's inputs. Then two hidden layers of 64: a plain, reasonable network for a table, not a tuned one."
    },
    {
      "code": "        opt = torch.optim.Adam(self.net.parameters(), lr=0.01)\n        loop.fit(self.net, opt, (x, t), (x, t), self.steps, batch_size=len(t), every=10**9)\n        return self",
      "note": "The `loop.py` from lesson 9, with the whole fold as one batch, so 200 epochs are 200 steps of Adam. It wants a set to report on and gets the training fold; `every` is so large that it never prints, and nothing is chosen from it."
    },
    {
      "code": "    def predict(self, X):\n        x = torch.tensor(self.scale.transform(X), dtype=torch.float32)\n        self.net.eval()\n        with torch.no_grad():\n            return self.net(x).argmax(dim=1).numpy()"
    },
    {
      "code": "def models():\n    return {\n        \"logistic regression\": make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000)),\n        \"gradient boosting\": HistGradientBoostingClassifier(random_state=0),\n        \"MLP, PyTorch\": TorchMLP(),\n    }",
      "note": "Logistic regression and gradient boosting exactly as `machine-learning` left them, and boosting with scikit-learn's defaults, untouched."
    },
    {
      "code": "def run(X, y):\n    folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)\n    for name, model in models().items():\n        scores, start = [], time.perf_counter()\n        for train, test in folds.split(X, y):\n            model.fit(X[train], y[train])\n            scores.append((model.predict(X[test]) == y[test]).mean())\n        seconds = time.perf_counter() - start\n        print(f\"{name:20s} accuracy {np.mean(scores):.3f}  worst fold {min(scores):.3f}  {seconds:6.2f} s\")",
      "note": "Five folds instead of one validation set, because on a few hundred rows one split is a handful of examples away from a different answer. Every model sees the same five splits, and the clock covers all five fits."
    }
  ]
}
```

**Every model is held to one processor**, and that is a decision about fairness, not speed. With
four processors each library divides its work its own way, and on a machine that is busy with
something else the division can cost more than the work. One processor each makes the clock measure
how much work a model does.

The first table is scikit-learn's breast cancer set: 569 tumours, 30 measurements each, and whether
it was malignant or benign. Save as `~/dl/cancer.py` and run it:

```schooling-example
{
  "language": "python",
  "file": "cancer.py",
  "parts": [
    {
      "code": "\"\"\"cancer: the breast cancer table that ships with scikit-learn, through bench.py.\"\"\"\nfrom sklearn.datasets import load_breast_cancer\n\nimport bench\n\nX, y = load_breast_cancer(return_X_y=True)",
      "note": "569 tumours, each described by 30 measurements taken from a cell image, and a label: malignant or benign. Like the digits, it ships inside scikit-learn."
    },
    {
      "code": "print(X.shape[0], \"rows,\", X.shape[1], \"columns,\", f\"{y.mean():.0%} benign\")\nbench.run(X, y)",
      "note": "The share of the majority class is the accuracy of a model that always answers \"benign\", the baseline every number below has to beat."
    }
  ]
}
```

```
PENDING cancer
```

**All three land within 1.2 points of each other, and the network is last.** Logistic regression
reaches 0.979, boosting 0.970 and the network 0.967. Each fold holds about 114 tumours, so one
tumour is almost a point, and these three differ by one or two tumours a fold. The network also had
the worst single fold, 0.930. Lesson 18 is about telling a difference from noise, and this one does
not qualify. What is not in doubt is that the network bought nothing.

**The clock separates them more than the accuracy does.** Logistic regression took 0.03 seconds for
all five folds, boosting 0.68 and the network 2.97, about four times boosting and a hundred times
logistic regression. Those seconds will be different on your machine, and they move from one run to
the next. The order is what to read.

Notice which model won. This table's 30 columns are measurements a pathologist chose because they
separate the two classes, and a weighted sum of them is nearly enough. **When somebody has already
done the feature engineering, there is little left for a network to learn**, and a linear model with
30 weights is a hard thing to beat. The next section builds a table where that is not true, and the
answer changes, though not towards the network.
