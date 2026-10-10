---
title: A prediction is not a decision
version: 1
---

Ana's first request arrives in one sentence: *"build us a churn model"*. It sounds like a
specification, and it is not one. **A model produces a number; a business does something.** Until
somebody says what will be done with the number, there is no way to tell a good model from a bad
one, because "good" means "leads to better actions", and nobody has named the action.

So the first job is to turn the sentence into a decision. At Feira em Casa it goes like this. The
retention team can send a subscriber a credit of **R$ 40** off the next box. Sent to somebody who
was about to leave, it keeps some of them. Sent to somebody who was staying anyway, it is R$ 40
given away. The team wants to know **whom to send it to, at the start of each month**. That is the
decision, and the model exists to inform it.

## Four questions that turn a request into a problem

**1. What is one row?** The unit the model scores. Here it is *a subscriber on the first day of a
month*, not a subscriber: the same person is scored again every month, with what has changed
since. A model scoring people once, ever, would be answering a different question.

**2. When is the prediction made, and what is known then?** The moment of prediction is the
first of the month, before the credit goes out. **Anything not known at that moment cannot be an
input**, however well it predicts. Lesson 4 is entirely about columns that break this rule without
looking as if they do.

**3. What exactly is being predicted, over what horizon?** *Cancels within the month that follows
the snapshot.* Not "will ever cancel", which is true of everybody eventually, and not "cancelled
last month", which is history. The horizon has to match the action: a credit sent today can only
change what happens over the next few weeks.

**4. What will be done with each answer?** Send the credit, or do not. Two actions, so this is a
**classification** problem: the model's job is to separate the people worth a credit from the
rest. When the thing predicted is a quantity, such as the minutes a delivery will take, it is a
**regression** problem, and lesson 5 starts on both.

## What the data says about the decision

The file already answers the first three questions, because it was built for this one. A short
program shows its shape. Save it as `frame.py` in `~/ml`:

```python
# frame.py
import pandas as pd

churn = pd.read_csv("data/churn.csv", parse_dates=["snapshot"])
print(f"{len(churn):,} rows, {churn['customer_id'].nunique():,} subscribers, "
      f"{churn['snapshot'].nunique()} monthly snapshots")
print(f"cancelled in the month after the snapshot: {churn['churned'].mean():.1%}")
months = churn.groupby("snapshot")["churned"].agg(subscribers="size", cancelled="sum")
print(months.tail(3).to_string())
```

```
ana@lab:~/ml$ python frame.py
62,885 rows, 7,583 subscribers, 18 monthly snapshots
cancelled in the month after the snapshot: 5.9%
            subscribers  cancelled
snapshot                          
2025-10-01         4098        281
2025-11-01         4137        284
2025-12-01         4146        248
```

**62,885 rows and 7,583 people**: each subscriber appears, on average, more than eight times. In
December 2025 the team would have scored 4,146 subscribers, and 248 of them went on to cancel,
which is the 5.9% of the second line, give or take a month.

Read that rate as the size of the haystack. **Roughly one row in seventeen is a cancellation**, so a
model that says "nobody cancels" is right about 94% of the time and useless every time. Lesson 2
makes that model on purpose, as the thing to beat, and lesson 13 is about what a rare class does
to every number that measures a model.

## The words this course uses

- **Features** are the columns the model reads: `skips_90d`, `city`, `tenure_months` and so on.
  Other books call them inputs, predictors or variables.
- **The target**, or **label**, is the column it predicts: `churned`.
- **A positive** is a row whose label is 1, here a cancellation. It is positive in the sense of
  "the thing looked for", which is why a positive is bad news for the business.
- **Fitting** or **training** is the step in which the model's numbers are chosen from data, and
  **scoring** or **predicting** is using them on rows it has not seen.
