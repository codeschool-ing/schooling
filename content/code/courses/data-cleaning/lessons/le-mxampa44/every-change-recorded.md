---
title: Every change, with its rule
version: 1
---

The log says how many values changed. An audit needs to know which ones, so `run.py` also writes
`out/changes.csv`, one row per changed value:

```
ana@lab:~/clean$ python -c "import pandas as pd; c = pd.read_csv('out/changes.csv', dtype=str); print(c.groupby(['table', 'column', 'rule']).size().to_string()); print(c[c['rule'].str.startswith('typed')].head(3).to_string(index=False))"
table      column       rule                         
customers  birth_year   century rule, lesson 10          105
                        placeholder, lesson 4            338
orders     customer_id  same person, lesson 5              2
           total        coupon above basket, lesson 9    137
                        typed total, lesson 9              7
 table    key column before  after                  rule
orders 100592  total 2516.0  251.6 typed total, lesson 9
orders 106842  total  458.5  45.85 typed total, lesson 9
orders 111955  total 2721.5 272.15 typed total, lesson 9
```

589 changes in five groups, and each group names the lesson whose rule made it. The first rows of
the typed totals show the shape: table, key, column, the value before, the value after, and the rule.

A change record answers questions that otherwise have no answer:

- **"Why is order 106842 R$ 45.85 when the system says R$ 458.50?"** Because its lines add up to
  R$ 45.85, by the rule of lesson 9, and the row says so.
- **"How much did cleaning change revenue?"** Sum `after` minus `before` over the order totals.
- **"Which customers did we touch?"** Every key is listed. If one of them asks, under the LGPD,
  what was done with their data, the answer is a filter, not an investigation.

Three choices make it trustworthy:

- **Changes are found by comparing, not by remembering.** `run.py` compares each raw total with the
  decided one and records every difference, so a rule that changed more than expected shows up
  here even if nobody planned it.
- **Only values that changed are recorded.** A flag such as `corporate` adds a column and changes
  no value, so it lives in the table, not in the record.
- **The rule is written in words that point at the decision**, here a lesson; in a company, the
  ticket, the e-mail or the meeting where it was agreed.

This is the same idea as lesson 9's flags, at the scale of a whole pipeline: **nothing changes
silently, and nothing changes without a reason somebody can read**.
