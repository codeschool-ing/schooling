---
title: Loading it, and what the file does not contain
version: 1
---

A saved model is only worth something if the model that comes back is the one that went in. The test
for that is direct: load it in a fresh process, score the 13,154 rows of `churn_2026.csv`, and compare
the chances with a model fitted again from scratch. Save this as `load_model.py`:

```python
# load_model.py
import numpy as np

import stored
from churn_model import build
from feira import load_churn

model, card = stored.load("churn-2025-12")
new = load_churn("data/churn_2026.csv")
loaded = model.predict_proba(new)[:, 1]

history = load_churn()
refitted = build().fit(history, history["churned"]).predict_proba(new)[:, 1]
print(f"{card['name']}, fitted on {card['data']} {card['sha256'][:12]}")
print(f"{len(new):,} chances from the file and from a fresh fit, identical: {np.array_equal(loaded, refitted)}")
```

```
ana@lab:~/ml$ python load_model.py
churn-2025-12, fitted on data/churn.csv 500d90cc1cfd
13,154 chances from the file and from a fresh fit, identical: True
```

**Identical, not close.** `np.array_equal` compares every one of the 13,154 numbers to the last bit. A
logistic regression on the same data and the same versions comes out the same each time, and the file
holds exactly what was fitted.

Now the same file from somewhere else. `joblib.load` from `/tmp`, which has the file's full path but
not the course's programs:

```
ana@lab:~/ml$ cd /tmp
ana@lab:/tmp$ python -c 'import joblib; joblib.load("/home/ana/ml/models/churn-2025-12.joblib")'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/joblib/numpy_pickle.py", line 755, in load
    obj = _unpickle(
          ^^^^^^^^^^
  File "/home/ana/ml/.venv/lib/python3.12/site-packages/joblib/numpy_pickle.py", line 632, in _unpickle
    obj = unpickler.load()
          ^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/pickle.py", line 1205, in load
    dispatch[key[0]](self)
  File "/usr/lib/python3.12/pickle.py", line 1530, in load_stack_global
    self.append(self.find_class(module, name))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/pickle.py", line 1572, in find_class
    __import__(module, level=0)
ModuleNotFoundError: No module named 'churn_model'
```

`No module named 'churn_model'`. **The file holds the learned numbers and the names of the code, not
the code.** Lesson 15's pipeline starts with `FunctionTransformer(add_shapes)`, and what was saved for
that step is the name `churn_model.add_shapes`, to be imported when the file is loaded. The same goes for
every scikit-learn class in it: the file says `sklearn.linear_model.LogisticRegression` and trusts that
whatever answers to that name later is the same thing. That is why `stored.load` checks the versions,
and why the card cannot replace keeping `churn_model.py` at the commit that fitted the model: the file
and the code it names go together, or the file is a riddle.

There is a sharper consequence. Loading the file **imports and runs whatever code it names**; that is how
`churn_model` came to be looked for at all. `joblib` files, like Python's `pickle` files underneath them,
are programs as much as data. **Load only files you made, or files from someone you would let run a
program on your machine.** A model downloaded from a stranger is a stranger's program. Formats that hold
only numbers exist for exactly that reason; for a model you fitted and keep yourself, `joblib` is the
ordinary choice.
