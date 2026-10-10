---
title: How a leak looks in the numbers
version: 1
---

A leak has symptoms, and none of them is proof. They are reasons to stop and ask where a column
comes from, which is the only proof there is.

**A score better than the problem allows.** Lesson 2's ceiling and the walk through lesson 3 give a
sense of what this data can do: an AUC around 0.8, a net value around R$ 900 per thousand rows.
A model at 0.958, or at 1.0, on a problem about whether people will cancel a box of vegetables, is
much more likely to be leaking than to be brilliant. Human behaviour is noisy, and a model that
says otherwise has found something that is not behaviour.

**One column doing most of the work.** When dropping a single column moves the score far more than
dropping any other, that column deserves an interview. Lesson 19 measures how much each column
contributes; the crude version is to rank the rows by each column alone and see how many leavers
land at the extreme. Save this as `suspects.py`:

```python
# suspects.py
import pandas as pd

churn = pd.read_csv("data/churn.csv")
columns = churn.select_dtypes("number").columns.drop("churned")
print(f"leavers among all rows: {churn['churned'].mean():.1%}")
print("leavers among the 10% of rows with the most extreme value of one column:")
rows = []
for col in columns:
    known = churn.dropna(subset=[col])
    k = len(known) // 10
    high = known.nlargest(k, col)["churned"].mean()
    low = known.nsmallest(k, col)["churned"].mean()
    rows.append((col, max(high, low), "highest" if high >= low else "lowest"))
for col, share, end in sorted(rows, key=lambda r: -r[1]):
    print(f"  {col:22} {share:6.1%}  ({end} values)")
```

```
ana@lab:~/ml$ python suspects.py
leavers among all rows: 5.9%
leavers among the 10% of rows with the most extreme value of one column:
  days_since_last_order   26.1%  (highest values)
  rating_90d              25.1%  (lowest values)
  skips_90d               13.9%  (highest values)
  days_since_login        12.6%  (highest values)
  late_90d                12.5%  (highest values)
  complaints_90d          12.0%  (highest values)
  support_calls_90d       10.1%  (highest values)
  orders_90d               8.0%  (lowest values)
  tenure_months            7.9%  (lowest values)
  price_month              7.5%  (highest values)
  age                      7.0%  (lowest values)
  app_user                 6.8%  (highest values)
```

The leak comes first, and that is useful; but it comes first by **one point**, ahead of
`rating_90d`, which is a perfectly legitimate column. A check like this finds a blatant leak, and
`cancel_reason`, if it were a number, would sit at the top with every leaver in it. A subtle leak is
subtle precisely because it looks like a good feature. **No check on the numbers alone could have
told these two apart**, and the next section is what does.

**A score that falls on newer data.** The time split and, after it, production. A model that does
markedly worse on later months than on the months it was validated on is either meeting a changed
world, which lesson 22 is about, or meeting the absence of something it leaned on.

**A relation that changes with the date.** `subtle.py`'s table is the most specific symptom there
is: a column whose meaning for the target shifts steadily with the snapshot date is very often
measured from a fixed point in time, the export, rather than from the row's own moment.
