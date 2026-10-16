---
title: From a business question to a kind of model
version: 1
---

Most failed machine-learning projects in BI fail at the first step: the question was not one a model
could answer, or it was answered with the wrong kind of model. Translating the question is the
analyst's job, and it comes before any algorithm.

| business question | what is predicted or found | kind |
|---|---|---|
| which customers will stop ordering in the next 90 days? | a category per customer: leaves or stays | supervised, classification |
| how much will each customer spend next quarter? | a number per customer | supervised, regression |
| how many boxes next week? | a number per week | forecasting, lessons 3 to 5 |
| which customers are alike? | groups | unsupervised, clustering |
| is this order unusual? | how far from normal an order is | unsupervised, anomaly detection |
| which offer should this visitor see? | an action | reinforcement, or an A/B test |

Three questions sort a request into a row.

1. **Is there a right answer that will be known later?** If yes, examples with the answer can be
   collected and the problem is supervised. "Will this customer leave?" is answered, eventually, by
   whether they leave.
2. **Is the answer a category or a number?** Classification or regression.
3. **Will the model's output change what happens?** If a churn model's flag triggers a discount, the
   customers it flags behave differently because of it, and next year's training data contains the
   model's own effect. That loop is lesson 18's subject.

**Forecasting is supervised learning with time as the input**, and lessons 3 to 5 already did it. The
discipline learnt there carries over intact: train on the past, test on a future the model never saw,
and compare against a simple baseline.
