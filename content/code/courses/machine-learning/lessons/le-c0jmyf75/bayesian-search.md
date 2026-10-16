---
title: Bayesian search, which learns where to look
version: 1
---

Grid and random search choose every candidate without looking at the results so far. **Bayesian
search** looks. After each fit, it builds a model of the score itself, a guess at how good every
untried setting would be, with an uncertainty attached, and chooses the next setting where that model
says the best improvement is most likely. Good regions get refined; unexplored regions get visited
when their uncertainty is large enough to be worth it.

Libraries do this well, Optuna and scikit-optimize among them, and the course installs neither
because the idea fits in about forty lines with what scikit-learn already has. The model of the score is a
**Gaussian process**, and the rule for choosing the next point is **expected improvement**. Two
hyperparameters are searched, the learning rate and the number of leaves, with the same 18 fits as
the other two searches. Save this as `bayes_search.py`:

```schooling-example
{
  "language": "python",
  "file": "bayes_search.py",
  "parts": [
    {
      "code": "# bayes_search.py\nimport numpy as np\nfrom scipy.stats import norm\nfrom sklearn.gaussian_process import GaussianProcessRegressor\nfrom sklearn.gaussian_process.kernels import Matern, WhiteKernel\nfrom sklearn.model_selection import cross_val_score\n\nfrom feira import by_time, load_churn\nfrom tuning import FEATURES, booster, time_folds, value_per_thousand\n\ntrain, _ = by_time(load_churn())\nfolds = list(time_folds(train))\n",
      "note": "The same folds, score and model as every other search here, from `tuning.py`."
    },
    {
      "code": "\ndef settings(point):\n    \"\"\"A point in [0, 1] x [0, 1] as a learning rate from 0.01 to 0.5 and 4 to 64 leaves.\"\"\"\n    return {\"learning_rate\": round(float(10 ** (-2 + 1.7 * point[0])), 3),\n            \"max_leaf_nodes\": int(round(4 * 16 ** point[1])), \"max_iter\": 150}\n\n\ndef score(point):\n    return cross_val_score(booster(**settings(point)), train[FEATURES], train[\"churned\"],\n                           cv=folds, scoring=value_per_thousand).mean()\n",
      "note": "**Two dials, mapped onto a unit square.** The learning rate runs from 0.01 to 0.5 on a log scale and the leaves from 4 to 64, so a step of the same size anywhere in the square is a change of the same proportion."
    },
    {
      "code": "\nrng = np.random.default_rng(0)\ntried = list(rng.random((5, 2)))                     # five points at random to start\nscores = [score(p) for p in tried]",
      "note": "Five settings at random, to give the search something to learn from."
    },
    {
      "code": "for step in range(13):\n    kernel = Matern(length_scale=0.25, nu=2.5) + WhiteKernel(noise_level=0.1)\n    gp = GaussianProcessRegressor(kernel, optimizer=None, normalize_y=True).fit(tried, scores)",
      "note": "**The surrogate.** A Gaussian process is fitted to the scores so far: a smooth guess of the score everywhere in the square, with an uncertainty that is small near the points tried and large far from them. Its smoothness is fixed here; a library would fit it."
    },
    {
      "code": "    candidates = rng.random((2000, 2))\n    mean, sd = gp.predict(candidates, return_std=True)\n    gain = mean - max(scores)                        # expected improvement over the best so far\n    z = gain / np.maximum(sd, 1e-9)\n    improvement = gain * norm.cdf(z) + sd * norm.pdf(z)\n    nxt = candidates[np.argmax(improvement)]\n    tried.append(nxt)\n    scores.append(score(nxt))\nbest = int(np.argmax(scores))\nprint(f\"{len(scores)} settings tried; best {scores[best]:.0f} at try {best + 1}: {settings(tried[best])}\")\nprint(\"scores in the order tried:\", \" \".join(f\"{s:.0f}\" for s in scores))",
      "note": "**Expected improvement.** For 2,000 random candidates, how much each is expected to beat the best score so far, counting both a high guess and a wide uncertainty. The candidate with the most is the next one fitted. That balance is what makes the search explore new ground and also refine good ground."
    }
  ]
}
```

```
ana@lab:~/ml$ python bayes_search.py
18 settings tried; best 846 at try 14: {'learning_rate': 0.124, 'max_leaf_nodes': 4, 'max_iter': 150}
scores in the order tried: 697 556 301 618 583 658 820 807 795 819 808 810 591 846 646 782 804 680
```

**The best setting scores R$ 846 per thousand rows**, at a learning rate of 0.124 with 4 leaves, the
smallest trees the range allows. Read the scores in the order they were tried: the five random starts
range from 301 to 697, and **the second point the search chose scored 820**, better than anything
random search found in 18 tries. The search learned from five fits that small trees and a moderate rate
were promising, and went straight there.

It also kept looking elsewhere: tries 13, 15 and 18 drop to between 591 and 680, which is the search
spending fits on regions it was unsure about. That is not waste. A search that never explores settles
on the first good region it finds.

## When it is worth it

Bayesian search pays when each fit is expensive, a minute or an hour, so that thinking about where to
look costs less than fitting at random. Here a fit takes a second, and its advantage over random search
is real but small. It also brings its own settings, the smoothness of the guess and how much to
explore, which is why a mature library is the better choice for real work, and this program is the
explanation of what such a library does.
