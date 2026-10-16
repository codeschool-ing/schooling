---
title: Scoring a file the model has never seen
version: 1
---

Back to the request that broke `by_hand.py`: chances for every subscriber in `churn_2026.csv`. With
the model in one object, the program is short. The model is fitted on **all** of `churn.csv` this
time, July 2024 to December 2025, because the test months have done their job: they measured the
model, and now they are the most recent evidence there is, including the months after the price rise.
Save this as `score_2026.py`:

```python
# score_2026.py
from churn_model import build
from feira import CREDIT, KEPT, SAVED, load_churn

history = load_churn()
new = load_churn("data/churn_2026.csv")
model = build().fit(history, history["churned"])
new["chance"] = model.predict_proba(new)[:, 1]
new["send"] = new["chance"] >= CREDIT / (SAVED * KEPT)
summary = new.groupby(["snapshot", "plan"], observed=True).agg(
    subscribers=("chance", "size"), mean_chance=("chance", "mean"), credits=("send", "sum"))
print(summary.round(3).to_string())
```

`churn_2026.csv` has no `churned` column, since nobody knows yet who will leave, and the pipeline
does not need one: `ColumnTransformer` only reads the columns it was told about.

```
ana@lab:~/ml$ python score_2026.py
                        subscribers  mean_chance  credits
snapshot   plan                                          
2026-01-01 fortnightly         1898        0.051       43
           weekly              2328        0.070      111
2026-02-01 fortnightly         1904        0.052       52
           monthly              174        0.111       10
           weekly              2310        0.072      111
2026-03-01 fortnightly         1912        0.054       61
           monthly              322        0.106       20
           weekly              2306        0.068       99
```

**The monthly plan was scored without complaint.** It appears from February, 174 subscribers and then
322, and `OneHotEncoder` gave it zeros in every plan column, as `encoders.py` showed in lesson 14. Its
chances still differ from the other plans, about 0.11 against 0.05 and 0.07, because the model reads
the rest of each row: these are people who joined weeks ago, and a short tenure is one of the strongest
signals it has. Which columns did the most is lesson 19's question.
Whether those chances are right is something no program can say in March 2026, because the answers
have not happened yet.

That is worth stating plainly, because it is the situation every deployed model is in. **On new data
the model is scored by time, not by a test set**: the labels for January arrive in February, and only
then does anybody know how good January's chances were. `churn_2026_labels.csv` holds those answers,
and lesson 22 compares them with this table. Until then, two things are already worth a look: a plan
the model never saw is a part of the population it knows least about, and a share of credits per
month that changes suddenly is a question to ask before anybody acts on it.
