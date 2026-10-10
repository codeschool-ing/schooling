---
title: What to ask for before you take a model on
version: 1
---

A model reaches a data engineer as something a modeller made. **What arrives with it decides
whether it can be run, checked and retrained by somebody else**, and the time to ask for what is
missing is before the handoff, not the night it breaks.

| ask for | why | at Ponto Final |
| --- | --- | --- |
| **the label, defined in code** | a sentence describing it is two implementations waiting to differ | `features.py`, the `NOT EXISTS` line |
| **the label's maturity** | it decides the gap between training and test, and when quality can be measured | 90 days |
| **the features, defined in code, as of a cutoff** | the same code must serve them, or there will be skew | `features.py` |
| **the model's definition, separate from its training data** | so it can be fitted again on new rows | `model.py` |
| **the deciding score, and its baseline** | so a retrained model can be judged the same way | average precision against the base rate, and lapses in the top 300 |
| **the expected input ranges** | they become the data contract | the checks in `validate.py` |
| **who uses the output, and how** | it decides the deployment and the threshold | marketing, three hundred vouchers a month |
| **who to call when it is wrong** | a model has an owner after go-live, or it has none | Ana, in this course |

Most of the table is not modelling at all. It is the same set of questions a data engineer asks of
any new data product: what does it mean, how is it computed, when is it complete, who reads it,
what happens when it is late. **A model is a data product whose output is a guess about the
future**, which only adds one question: how will anybody find out whether the guesses were right?
Lesson 9 is the answer to that.
