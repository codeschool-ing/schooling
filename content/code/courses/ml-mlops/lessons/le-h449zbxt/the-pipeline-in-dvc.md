---
title: The pipeline, as stages DVC can run
version: 1
---

Lesson 5's `pipeline.sh` ran every step, every time. **DVC runs the same steps, but it knows what
each one reads and writes**, so it can skip a step whose inputs have not changed and record the hash
of everything it produced. The steps are declared in `dvc.yaml`. Save it in `~/ml`:

```yaml
# dvc.yaml: the pipeline of lesson 5, as stages DVC can run, skip and compare.
stages:
  dataset:
    cmd: >-
      python build_dataset.py 2025-08-31 data/train.csv &&
      python build_dataset.py 2025-11-30 data/test.csv &&
      python validate.py data/train.csv &&
      python validate.py data/test.csv
    deps: [build_dataset.py, validate.py, features.py, project.py, shop.db]
    outs: [data/train.csv, data/test.csv]
  train:
    cmd: python train.py data/train.csv models/lapse.joblib
    deps: [train.py, model.py, data/train.csv]
    outs: [models/lapse.joblib, models/lapse.json]
  evaluate:
    cmd: python evaluate.py models/lapse.joblib data/test.csv
    deps: [evaluate.py, models/lapse.joblib, data/test.csv]
    metrics:
      - models/lapse.scores.json:
          cache: false
```

Each stage has a command, the files it depends on (`deps`) and the files it produces (`outs`). The
dataset stage depends on `shop.db` and on the code that reads it, so a new night of purchases or an
edit to `features.py` both reach it. The scores are a **metric** rather than an output: DVC leaves
them in Git, where they are small enough to diff, and `cache: false` says so.

```
ana@dev:~/ml$ dvc repro
'shop.db.dvc' didn't change, skipping
Running stage 'dataset':
> python build_dataset.py 2025-08-31 data/train.csv && python build_dataset.py 2025-11-30 data/test.csv && python validate.py data/train.csv && python validate.py data/test.csv
data/train.csv: 2863 members as of 2025-08-31, 16.6% lapsed
data/test.csv: 3130 members as of 2025-11-30, 16.9% lapsed
data/train.csv: 2863 rows, every check passed
data/test.csv: 3130 rows, every check passed
Generating lock file 'dvc.lock'
Updating lock file 'dvc.lock'

Running stage 'train':
> python train.py data/train.csv models/lapse.joblib
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
Updating lock file 'dvc.lock'

Running stage 'evaluate':
> python evaluate.py models/lapse.joblib data/test.csv
{
  "test": "data/test.csv",
  "cutoff": "2025-11-30",
  "members": 3130,
  "lapsed": 530,
  "roc_auc": 0.793,
  "average_precision": 0.522,
  "baseline_average_precision": 0.169,
  "lapsed_in_top_300": 190,
  "said": 0.177
}
Updating lock file 'dvc.lock'

To track the changes with git, run:

	git add data/.gitignore models/.gitignore dvc.lock

To enable auto staging, run:

	dvc config core.autostage true
Use `dvc push` to send your updates to remote storage.
ana@dev:~/ml$ dvc dag
       +-------------+    
       | shop.db.dvc |    
       +-------------+    
              *           
              *           
              *           
         +---------+      
         | dataset |      
         +---------+      
         **        **     
       **            *    
      *               **  
+-------+               * 
| train |             **  
+-------+            *    
         **        **     
           **    **       
             *  *         
        +----------+      
        | evaluate |      
        +----------+      
ana@dev:~/ml$ dvc push
5 files pushed
```

`dvc repro` worked out the order from the files, ran the three stages, and wrote **`dvc.lock`**: the
hash of every dependency and every output, as they were on this run. `dvc dag` draws the order it
found. `dvc push` copies the outputs to the remote, so the model of this commit is kept as safely as
the data it came from.

The scores are lesson 5's, to the digit: 0.793, 0.522, 190 in the top 300. **The steps are the same
programs, so the model is the same model.**
