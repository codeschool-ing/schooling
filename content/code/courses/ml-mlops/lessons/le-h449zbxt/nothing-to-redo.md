---
title: Nothing changed, so nothing runs
version: 1
---

Run the pipeline again straight away:

```
ana@dev:~/ml$ dvc repro
'shop.db.dvc' didn't change, skipping
Stage 'dataset' didn't change, skipping
Stage 'train' didn't change, skipping
Stage 'evaluate' didn't change, skipping
Data and pipelines are up to date.
ana@dev:~/ml$ git add . && git commit -qm "lapse model v1" && git tag v1 && git log --oneline
ffa462d lapse model v1
4bb4b2d the lapse pipeline, and the shop it reads
```

**Every stage is skipped**, because every dependency has the hash `dvc.lock` recorded. On Ponto
Final's shop that saves seconds; on a dataset that takes an hour to build it saves the hour, and on a
nightly schedule it means a night with no new data costs nothing.

Then the commit that makes this a version. `git add .` takes `dvc.lock`, the two `.gitignore` files
DVC wrote and the scores, and the tag `v1` gives the commit a name a person can type. **The commit
`v1` now names everything**: the code, the shop through its pointer, the exact training file and
model through `dvc.lock`, and the scores in plain text.
