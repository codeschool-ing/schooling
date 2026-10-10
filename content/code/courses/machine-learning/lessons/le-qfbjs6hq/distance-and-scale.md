---
title: Distance needs a common scale
version: 1
---

The *raw* lines of `knn.py` are the ones to dwell on. Unscaled, the model with 15 neighbours sends
120 credits and makes R$ 96; scaled, it sends 332 and makes R$ 7,744. **Same rows, same k, eighty
times the money.** The only thing that changed is the units of the axes.

A distance adds up differences across columns. In raw units, `price_month` runs from about R$ 180 to
R$ 760, so two subscribers whose prices differ by R$ 100 are 100 apart on that axis. Their skips in
the last 90 days, the strongest single signal after rating, differ by at most a handful. **The
neighbourhood is decided almost entirely by price**, because price is measured in the biggest
numbers, and skips, ratings and complaints barely count. The model is finding subscribers with a
similar bill and calling them alike.

`StandardScaler` puts every column in standard deviations, so a typical difference in price and a
typical difference in skips count the same. That is a choice, not a neutral fact: it says every
column matters equally to "similar", which is not true either, but it is far less wrong than letting
the unit of each column decide.

This is the same lesson as the weights of lesson 5, in a sharper form. A linear model's predictions
do not depend on the units unless it is penalised; a distance-based model's predictions depend on
nothing else. **Anything built on distance needs its columns on a common scale**: nearest neighbours,
the support vector machines later in this lesson, and k-means in lesson 16.

## Two practical costs

**Prediction is slow, and grows with the data.** Each prediction compares the new row with every
stored row, or with a clever index of them. `knn.py` spends nearly all of its minute predicting.
A model that has to answer at checkout, in milliseconds, against millions of stored rows, needs
an approximate index, which is its own engineering.

**Gaps have no distance.** A missing rating cannot be subtracted from anything, so the program fills
gaps with the training medians first, as `logistic.py` did. A neighbour filled in that way is
*similar* to everybody with a median rating, which is a fiction worth remembering when the share of
gaps is large.
