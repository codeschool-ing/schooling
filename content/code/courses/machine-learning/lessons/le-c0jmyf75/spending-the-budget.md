---
title: Spending a tuning budget well
version: 1
---

A search costs fits, and fits cost time. Most of what makes tuning efficient is deciding what not to
try.

**Know which dials matter.** For gradient boosting the learning rate, the size of each tree and the
number of trees matter most, and they interact: a lower rate needs more trees. Regularisation settings
matter less. For a random forest, `max_features` and the leaf size matter, and the number of trees only
needs to be large enough. A search over dials that change nothing is a search spent on noise.

**Let early stopping set the number of trees.** Lesson 8 showed that early stopping measures the right
number of trees for a given rate. That removes the most expensive dial from the search: fix a low rate,
let early stopping stop, and tune the rest.

**Search coarse, then fine.** A first random search over wide ranges on a log scale finds the region;
a second, narrower search refines it. Spending the whole budget at once on a fine grid over the wrong
region is the common failure.

**Stop when the gains are inside the noise.** The spread across folds in `baseline_cv.py` was hundreds of
reais per thousand rows. A setting that wins by twenty has not won. Past that point, effort is better
spent elsewhere: lesson 14's features usually move a model more than lesson 9's dials.

**Do not tune on the test.** It is worth saying a last time because tuning is where it most often
happens: a person who runs a search, looks at the test, adjusts the ranges and searches again has made
the test a validation set, and the number they report is the optimistic one.

**Write down what was tried.** The ranges, the number of candidates, the folds, the score, the seed.
Lesson 15 makes the whole pipeline reproducible; a tuned model whose search nobody can repeat is one
nobody can check either.
