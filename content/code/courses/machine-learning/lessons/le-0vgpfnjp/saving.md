---
title: A model in a file, and the card that goes with it
version: 1
---

Every program so far has fitted its model, used it and thrown it away when it finished. That was fine
while the question was *how good is it*. The question now is *who uses it*: the retention team's system,
which asks about one subscriber at a time, all day, and must get the same answer the course has been
measuring. That needs the fitted model to outlive the program that fitted it, which means writing it to a
file.

Writing it is one call, `joblib.dump`. The harder part is lesson 15's list: a model file is only as
useful as the record of **which data, which code and which versions** produced it. So the course's
fourth shared file saves both, the model and a small card describing it, and refuses to load the model
anywhere the card does not hold. Save this as `stored.py`:

```python
# stored.py
"""Save a fitted model with a record of what made it, and load it only where that record holds."""
import hashlib
import json
import platform
from pathlib import Path

import joblib
import numpy
import pandas
import sklearn

MODELS = Path("models")


def versions():
    return {"python": platform.python_version(), "scikit-learn": sklearn.__version__,
            "pandas": pandas.__version__, "numpy": numpy.__version__}


def save(model, name, data, rows):
    MODELS.mkdir(exist_ok=True)
    joblib.dump(model, MODELS / f"{name}.joblib")
    card = {"name": name, "data": data, "sha256": hashlib.sha256(Path(data).read_bytes()).hexdigest(),
            "rows": len(rows), "from": str(rows["snapshot"].min().date()),
            "to": str(rows["snapshot"].max().date()), "versions": versions()}
    (MODELS / f"{name}.json").write_text(json.dumps(card, indent=2) + "\n")
    return card


def load(name):
    card = json.loads((MODELS / f"{name}.json").read_text())
    if card["versions"] != versions():
        raise RuntimeError(f"{name} was saved by {card['versions']}, and this is {versions()}")
    return joblib.load(MODELS / f"{name}.joblib"), card
```

The model to save is lesson 15's pipeline, fitted on all of `churn.csv` as `score_2026.py` fitted it.
It is the logistic regression rather than the boosted trees on purpose: lesson 15 made it one object that
takes the raw table, with its seven extra columns and its encoders inside, and **the object that takes
the raw table is the one worth serving**. Anything the caller had to prepare first would be a second
copy of the preparation, and the next sections show what a second copy costs. Save this as
`save_model.py`:

```python
# save_model.py
import stored
from churn_model import build
from feira import load_churn

history = load_churn()
model = build().fit(history, history["churned"])
card = stored.save(model, "churn-2025-12", "data/churn.csv", history)
print(f"saved {card['name']}: {card['rows']:,} rows from {card['from']} to {card['to']}")
```

```
ana@lab:~/ml$ python save_model.py
saved churn-2025-12: 62,885 rows from 2024-07-01 to 2025-12-01
ana@lab:~/ml$ ls -l models
total 12
-rw-r--r-- 1 ana ana 7258 Oct 16 01:33 churn-2025-12.joblib
-rw-r--r-- 1 ana ana  319 Oct 16 01:33 churn-2025-12.json
```

**The whole model is 7,258 bytes.** Thirty-six weights and an intercept, a median, a mean and a
standard deviation for each number, and the list of values each word column had. That is everything the
pipeline learned from 62,885 rows, and it is why a logistic regression is easy to move around. Lesson 8's
forests, a hundred deep trees each, run to megabytes; nothing below changes except the size.

The name says what the model is and when it stops knowing things: **churn, fitted on data to December
2025**. A name like `model_final_v2` says nothing in six months, when there are four of them.

The card is the other half:

```
ana@lab:~/ml$ cat models/churn-2025-12.json
{
  "name": "churn-2025-12",
  "data": "data/churn.csv",
  "sha256": "500d90cc1cfdfced677236baa90fb269e5c2731b344e36cd361e454b535c257a",
  "rows": 62885,
  "from": "2024-07-01",
  "to": "2025-12-01",
  "versions": {
    "python": "3.12.3",
    "scikit-learn": "1.9.1",
    "pandas": "3.0.6",
    "numpy": "2.5.3"
  }
}
```

`sha256` is lesson 1's fingerprint of `churn.csv`, so anybody holding the card can check they have the
same data the model learned from. `versions` is what `load` compares. The code that built the model is
the one thing the card does not hold, and the next section shows why it cannot.
