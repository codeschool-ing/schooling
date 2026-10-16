---
title: Running the four steps as one
version: 1
---

Four steps typed by hand are four chances to type one wrong. **A pipeline is the steps written down
in order, run the same way every time, stopping at the first failure.** At this size a shell script
is enough. Save this as `pipeline.sh`:

```sh
# pipeline.sh: the lapse model, from the shop to a scored model, stopping at the first failure.
set -e
cd "$(dirname "$0")"
python build_dataset.py 2025-08-31 data/train.csv
python build_dataset.py 2025-11-30 data/test.csv
python validate.py data/train.csv
python validate.py data/test.csv
python train.py data/train.csv models/lapse.joblib
python evaluate.py models/lapse.joblib data/test.csv
```

`set -e` is the line that makes it a pipeline: **the script stops the moment any command exits with
a failure**, so a refused dataset or a failed contract never reaches `train.py`. `cd "$(dirname
"$0")"` moves into the script's own directory first, so it runs the same from anywhere. The dates
are here, in one place, where a reviewer sees them.

Run it from your home directory, to prove the directory no longer matters:

```
ana@dev:~$ sh ml/pipeline.sh
data/train.csv: 2863 members as of 2025-08-31, 16.6% lapsed
data/test.csv: 3130 members as of 2025-11-30, 16.9% lapsed
data/train.csv: 2863 rows, every check passed
data/test.csv: 3130 rows, every check passed
{
  "model": "models/lapse.joblib",
  "trained_on": "data/train.csv",
  "data_sha256": "d04183235c0e66c2",
  "cutoff": "2025-08-31",
  "rows": 2863,
  "scikit_learn": "1.9.1"
}
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
```

**Every number is the same as when the steps ran one at a time**, down to the training file's
fingerprint, `d04183235c0e66c2`. That is what makes a pipeline worth having: run it again tomorrow
on the same data and it produces the same model; run it on new data and the only differences are
the ones the data caused.

## What a scheduler adds

`pipeline.sh` runs when somebody types it. In production it runs on a schedule, after the night's
load, and the steps become tasks in an orchestrator: Airflow, Dagster or Prefect, which
`pipelines-etl` taught. The orchestrator adds what a shell script lacks: retries, a record of every
run, an alert when one fails, and the rule that training waits until the shop's load has finished.
**Nothing about the steps changes**: each is still a program with a file in and a file out, which is
exactly the shape an orchestrator expects. Lesson 7 uses DVC to run the same steps and to skip the
ones whose inputs have not changed.
