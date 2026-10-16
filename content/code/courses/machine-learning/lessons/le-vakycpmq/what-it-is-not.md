---
title: What an explanation is not
version: 1
---

Every tool in this lesson answers a question about **the model**. The questions people bring to it are
usually about **the world**, and the gap between the two is where explanations do harm.

**An important column is not a cause.** Ratings are the most important column by every measure here,
and nobody believes that ratings make people leave. Disappointing boxes do both: they lower the rating
and they cause the cancellation. A manager who reads the importance table and decides to raise ratings,
by prompting happy customers to rate, say, would raise the column and leave the churn exactly where it
was. The model would then give those customers lower chances and be wrong about them.

**A contribution is not the effect of an action.** The SHAP value of +2.86 for one subscriber's rating
says how much that rating moved the model's output, holding nothing in the world fixed. What a credit,
a call or a better box would do to that subscriber is a different question, and the data in this course
cannot answer it, because nobody ever received a credit at random. Answering it takes an experiment:
send the credit to a random half of the subscribers the model selects, and compare. Lesson 11's 30%,
the share of leavers a credit keeps, is exactly the number such an experiment measures.

**Correlated columns blur the credit.** `rating_90d` and `unhappy` say nearly the same thing. A tree may
use one and ignore the other, a logistic regression splits the weight between them, permutation
importance underrates both, and SHAP gives each a share that depends on the model's arbitrary choices.
Before concluding that a column does not matter, check whether another column is carrying it.

**An explanation can be wrong in the same way the model is.** The monthly-plan section found a large
contribution that came from the encoding, not from anything about the subscribers. SHAP would have
reported it just as faithfully. Explanations are worth most when they are read with the scepticism of
lesson 4: when one is surprising, ask what in the data or the preparation could have produced it, before
believing it says something about customers.

What the tools are good for is checking, communicating and debugging: **checking** that the model learned
shapes a person would recognise, **communicating** why a subscriber was chosen, and **debugging** a model
whose behaviour on new data looks odd, which is exactly what found the monthly-plan artefact.
