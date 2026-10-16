---
title: The code goes into Git
version: 1
---

`~/ml` becomes a Git repository. Before the first commit, Git has to be told what not to keep,
because some files in the directory are not code. Save this as `.gitignore`, with the dot:

```
features.db
mlflow.db
mlruns/
__pycache__/
```

`features.db` is lesson 6's store, rebuilt from the shop at any time. `mlflow.db` and `mlruns/` are
where MLflow will keep its runs from section 08, a record of their own that does not belong in the
code's history. `shop.db` is not in the list: it is data, and the next section hands it to DVC.

```
ana@dev:~/ml$ git init -q && dvc init -q && git status --short | head -n 4
A  .dvc/.gitignore
A  .dvc/config
A  .dvcignore
?? .gitignore
```

`git init` makes the repository and `dvc init` adds DVC's own directory, `.dvc`, beside Git's.
**Nothing is committed yet**, on purpose: `shop.db` is untracked and not ignored, so a `git add .`
now would put six megabytes of SQLite into the code's history, where every clone would carry it
forever. The next section moves it to DVC first.
