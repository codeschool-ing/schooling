---
title: Build one, adopt one, or go without
version: 1
---

`featurestore.py` has every part a feature store has, and none of what makes one hold up at scale.
**What the products add is operations, not ideas:**

| a product adds | which in `featurestore.py` is |
| --- | --- |
| a registry of feature views, with owners and descriptions | the docstring, and Ana's memory |
| materialisation on a schedule, with retries and alerts | a command somebody runs |
| an online store that serves thousands of reads a second | one SQLite file |
| freshness monitoring per feature view | nothing |
| reuse: one view, read by many models | one model |

**Feast** is the open-source one, and its vocabulary is the one section 03 used: entities, feature
views, an offline and an online store, `materialize` and `get_historical_features`. It stores
nothing of its own; it drives the warehouse and the key-value store you already have. The clouds
sell managed ones inside their machine learning platforms, and data platforms such as Databricks
include one. **None of them was run for this course**, and nothing here depends on any of them.

**Go without one** while a single model reads a handful of features from one warehouse, as Ponto
Final does now. A well-tested `features.py` and the discipline of computing as of a cutoff give the
reproducibility; a nightly batch table of scores, which lesson 8 builds, needs no online store at
all.

**Build or adopt one** when the second model wants the first one's features, when a service needs
features in milliseconds, or when two teams start computing the same feature in two places. That
last one is the signal to watch for, because it is lesson 5's skew arriving through the
organisation rather than through the code.
