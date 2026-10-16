---
title: Parameters and hyperparameters
version: 1
---

Every model so far has had two kinds of number in it, and the difference decides who sets them.

**Parameters are learned by `fit`.** The weights of lesson 5's line, the cuts and leaf values of
lesson 7's tree, the hundreds of small trees of lesson 8: nobody types them, the data chooses them,
and there are often thousands.

**Hyperparameters are set before `fit`, by a person.** The depth of a tree, the number of
neighbours, `alpha`, `C`, the learning rate, how many leaves a boosted tree may have. They decide
*how* the model learns, and the data cannot choose them directly, because each value gives a
different model whose quality is only known after fitting it.

| model | its parameters | some of its hyperparameters |
|---|---|---|
| linear regression with ridge | the weights | `alpha` |
| k-nearest neighbours | none: it stores the rows | `n_neighbors`, the scaling |
| decision tree | the cuts and the leaf values | `max_depth`, `min_samples_leaf`, `ccp_alpha` |
| HistGradientBoosting | every tree in the sum | `learning_rate`, `max_iter`, `max_leaf_nodes`, `min_samples_leaf`, `l2_regularization` |

**Tuning** is choosing hyperparameters by trying them: fit with one setting, score it on validation
data, try another, keep the best. It is the same discipline lesson 2 applied to a rule and lesson 3
named: the choice is learning, so it is made on rows the final test never sees.

Lesson 8 kept lesson 2's HistGradientBoosting at its defaults and settled the question of which
library to use by noting that the ensembles tie. This lesson asks the next question. **The defaults
are somebody else's guess about data they never saw. Is a search worth its cost?**
