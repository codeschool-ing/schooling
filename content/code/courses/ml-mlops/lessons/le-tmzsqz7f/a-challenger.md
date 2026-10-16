---
title: A challenger, through the same pipeline
version: 1
---

A challenger is not a model somebody trains in a notebook. **It is the pipeline of lessons 5 to 7
run on new dates**, so it arrives with a commit, a data hash, a test and a registry entry like the
champion did. Three things change before `dvc repro`.

**First, the programs of lessons 8 to 10 go into Git.** `log_run.py` refuses a working tree with
anything uncommitted, and the batch, the service and the checks are code like any other. The log of
requests is not, so it joins the ignored files:

```
ana@dev:~/ml$ printf 'requests.log\n' >> .gitignore && git add .gitignore *.py && git commit -qm "serving, monitoring and drift" && git log --oneline -n 1
f25f8cc serving, monitoring and drift
```

**Second, the recipe is version 1's.** The working tree still holds version 2's `model.py`, the
balanced weights lesson 7 rejected. Git can bring back one file from any commit, and the champion's
recipe is the one a challenger should improve on, by changing only the data:

```
ana@dev:~/ml$ git checkout v1 -- model.py && git diff --stat HEAD
 model.py | 8 ++------
 1 file changed, 2 insertions(+), 6 deletions(-)
```

**Third, the dates.** `dvc.yaml` names the training and test nights in the `dataset` stage. The
rule of the previous section gives 28 December 2025 and 29 March 2026; `sed` changes the two
dates in place, and `git diff` shows exactly what changed:

```
ana@dev:~/ml$ sed -i 's/2025-08-31/2025-12-28/; s/2025-11-30/2026-03-29/' dvc.yaml && git diff dvc.yaml
diff --git a/dvc.yaml b/dvc.yaml
index e34c9ea..2a836fa 100644
--- a/dvc.yaml
+++ b/dvc.yaml
@@ -2,8 +2,8 @@
 stages:
   dataset:
     cmd: >-
-      python build_dataset.py 2025-08-31 data/train.csv &&
-      python build_dataset.py 2025-11-30 data/test.csv &&
+      python build_dataset.py 2025-12-28 data/train.csv &&
+      python build_dataset.py 2026-03-29 data/test.csv &&
       python validate.py data/train.csv &&
       python validate.py data/test.csv
     deps: [build_dataset.py, validate.py, features.py, project.py, shop.db]
```

Then the pipeline. DVC sees that `shop.db`, `model.py` and `dvc.yaml` changed, so it reruns all three
stages, and `evaluate.py` prints the challenger's test:

```
ana@dev:~/ml$ dvc repro -q
data/train.csv: 3201 members as of 2025-12-28, 17.0% lapsed
data/test.csv: 3429 members as of 2026-03-29, 21.0% lapsed
data/train.csv: 3201 rows, every check passed
data/test.csv: 3429 rows, every check passed
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "6892fba5956be6b8",
  "cutoff": "2025-12-28",
  "rows": 3201,
  "scikit_learn": "1.9.1"
}
{
  "test": "data/test.csv",
  "cutoff": "2026-03-29",
  "members": 3429,
  "lapsed": 720,
  "roc_auc": 0.745,
  "average_precision": 0.5,
  "baseline_average_precision": 0.21,
  "lapsed_in_top_300": 196,
  "said": 0.175
}
```

Commit it, tag it and record it, exactly as lesson 7 did version 1:

```
ana@dev:~/ml$ git add . && git commit -qm "lapse model v3: retrained on 28 December 2025" && git tag v3 && python log_run.py
Registered model 'lapse' already exists. Creating a new version of this model...
Created version '3' of model 'lapse'.
run 9e55a691, registered as lapse version 3
```

**Version 3 is in the registry, and the alias did not move.** Registering is recording; promoting is
a decision, and the next section makes it.
