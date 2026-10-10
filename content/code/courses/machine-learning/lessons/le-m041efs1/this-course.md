---
title: What this course is, and the order it goes in
version: 1
---

**Most machine learning courses open with linear regression.** This one opens with four lessons
in which nothing is fitted that you would keep, and that is the decision the rest of it rests on.
Fitting a model is three lines of scikit-learn. What decides whether the model is any use is
everything around those three lines: what it is for, what it has to beat, how it is tested, and
whether the test was honest.

So the course goes in this order:

| lessons | what they are about |
|---|---|
| 1 to 4 | **the problem before the model**: what the model decides and what an error costs (1), the trivial rule it has to beat (2), the split that tests it honestly (3), and the leaks that make a test lie (4) |
| 5 to 9 | **the algorithms**: linear and logistic regression, nearest neighbours, naive Bayes and support vector machines, trees, forests and boosting, and how to set their dials |
| 10 to 13 | **measuring them**: the metrics for a classifier and for a regression, the threshold that turns a probability into an action, and what happens when one class is rare |
| 14 and 15 | **the features and the pipeline** that keeps them honest |
| 16 to 18 | **without a label**: clustering, dimensionality reduction and recommendation |
| 19 and 20 | **explaining a model and checking whom it harms** |
| 21 and 22 | **after the notebook**: a model behind an address, scored in batches, and watched |

**Lessons 1 to 4 are the ones that are easy to skip and expensive to have skipped.** A model that
beats nothing, tested on a split that leaks, measured with a metric nobody's decision depends on,
produces a number that looks exactly like a good one. Lesson 4 shows a model scoring 0.95 that is
worth nothing, and the only thing wrong with it is a column.

## What it assumes

**`python-data` and `statistics`.** You already handle pandas and NumPy without looking things up:
a `DataFrame`, `groupby`, a boolean mask, `merge`. This course never explains them again. And you
already think in samples and uncertainty: a mean has a spread, a difference can be chance, and a
test set is a sample like any other. Lesson 2 leans on that when it asks whether a model really
beat its baseline.

## What it leaves to other courses

- **Neural networks** are `deep-learning`, the next course in the track. Everything here runs on
  a processor in seconds; that is the line between the two.
- **The machinery of production**, meaning feature stores, scheduled retraining, model registries
  and deployment pipelines, is `ml-mlops`. Lessons 21 and 22 put one model behind an address
  and watch it, which is what a data scientist does with their own hands. The platform that does
  it for a hundred models is somebody else's job.
- **Cleaning the data** was `data-cleaning`. The files here are tidy on purpose, apart from the
  gaps a model has to cope with, so that the attention goes on the model.

## How a lesson works

Every lesson uses the same folder and the same data, which you build in the next two sections.
**Each program a lesson runs is printed in full in that lesson**, and every transcript is what
that program printed when the course was recorded. You save the program, run it, and should see
the same numbers. Where a number of yours differs, the cause is almost always a version, and
lesson 15 explains why that matters more than it sounds.

The last section of each lesson is a drill. The questions in it are not marked, and each wrong
answer says what belief would have led to it, which is the reason to answer them honestly
rather than quickly.
