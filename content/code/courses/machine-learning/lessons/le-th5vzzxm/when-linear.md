---
title: When a linear model is the right choice
version: 1
---

On the churn data, logistic regression made R$ 16,424 on the test months and gradient boosting
R$ 21,672. That is a real gap, about a quarter, and on this evidence the box wins. That is often
the right decision, and the reasons it sometimes is not are worth knowing before lesson 8 makes the
box larger.

**A linear model is legible.** Its whole content is a short list of numbers, and the list can be
checked against what people who know the business believe. When a weight comes out with the wrong
sign, say late deliveries making people *less* likely to leave, that is a finding: a leak, a bug in
a column or a surprise about customers, and each is worth knowing. A boosted model with the same
fault is harder to catch.

**It is stable.** Refitted next month on slightly different rows, its weights move a little; the
predictions for a given subscriber move a little. Some models change their minds about individual
rows a great deal between fits, which is a problem when the retention team has already phoned
somebody.

**It degrades gracefully outside the data.** A delivery of 45 km, longer than anything in training,
gets a prediction that continues the line: long, roughly right. A tree, lesson 7 shows, predicts the
same as for the longest delivery it saw, which is wrong in a different and less obvious way.

**It is cheap to run and to explain to a regulator.** In credit, insurance and health, the
explanation is sometimes a legal requirement rather than a courtesy, and lesson 20 comes back to
that.

Against all of that: **it only finds the shapes it is given.** The churn data has a threshold in
it, people whose average rating falls below a certain point leave much more often, and an
interaction between lateness and being new. Logistic regression sees a straight-line version of
each, and the boosted model sees them as they are. That is most of the R$ 5,248 between them.

The practical conclusion is a habit rather than a rule. **Fit the linear model first**, always: it
is the strongest baseline there is, it takes a minute, and its weights tell you whether the data
makes sense. Then fit the box, and ask whether its gain is worth what the linear model was giving.
Here, with this gap, Ana would choose the box and keep the linear model as its check.
