#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of ml-mlops, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh > out.txt   # needs the lab lesson 1 builds
#
# It puts ~/ml back to the shop as lesson 1 leaves it and stages the programs
# of lessons 1 to 6 that the pipeline uses, removes any Git, DVC and MLflow
# state of ana's, installs MLflow and DVC with the lesson's own pip line
# (output not quoted), then runs the lesson in order. The MLflow server of
# the-page is started in the background, the way the lesson starts it in a
# second terminal, and stopped at the end by pid.
#
# MEASURED AND QUOTED WITHOUT A TRANSCRIPT: "over 2 GB" for the server with
# its default job workers, the sum of the resident memory of its processes,
# read with ps on the recording machine while the lesson was being written.
#
# Hashes of shop.db and of the model file depend on the SQLite and library
# builds; the lesson says so. Run ids and dates change on every run.
#
# A line that starts with ana@dev:~/ml$ is what ana typed and what it printed.
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
exec 9>/var/tmp/mlops-capture.lock; flock 9
F="python3 $COURSE/lab/fences.py"; L7=$COURSE/lessons/le-h449zbxt

quiet lab project
quiet lab exec 'rm -rf ~/dvc-store ~/.gitconfig; pkill -f "[m]lflow server" || true'
stage features.py le-xpaf8cg8/supervised.md
stage model.py le-fcd08ha8/the-trap.md
stage project.py le-d2vqq7mj/from-scripts-to-steps.md
for p in build_dataset validate train evaluate; do
  stage $p.py le-d2vqq7mj/$( case $p in build_dataset) echo building-the-dataset;; validate) echo a-data-contract;;
                              train) echo training-as-a-step;; evaluate) echo evaluating-as-a-step;; esac).md
done
stage pipeline.sh le-d2vqq7mj/running-the-pipeline.md
stage featurestore.py le-9amgywjz/the-store.md

quiet lab exec "$($F block $L7/installing-the-tools.md 'pip install mlflow==3.17.0 dvc==3.67.1')"
quiet lab exec "$($F block $L7/installing-the-tools.md 'git config --global user.name "Ana"')"
block installing-the-tools
on 'git --version; dvc --version; mlflow --version'

$F block $L7/code-in-git.md 'features.db' | put .gitignore
block code-in-git
on 'git init -q && dvc init -q && git status --short | head -n 4'

block data-in-dvc
on 'dvc add shop.db'
on 'cat shop.db.dvc'
on 'dvc remote add -d store ~/dvc-store'
on 'git add . && git commit -qm "the lapse pipeline, and the shop it reads" && git log --oneline'

stage dvc.yaml le-h449zbxt/the-pipeline-in-dvc.md
block the-pipeline-in-dvc
on 'dvc repro'
on 'dvc dag'
on 'dvc push'

block nothing-to-redo
on 'dvc repro'
on 'git add . && git commit -qm "lapse model v1" && git tag v1 && git log --oneline'

stage log_run.py le-h449zbxt/the-registry.md
stage champion.py le-h449zbxt/the-registry.md
block the-registry
on 'git add log_run.py champion.py && git commit -qm "record runs in MLflow"'
on 'python log_run.py'
on 'python champion.py 1'

stage experiments.py le-h449zbxt/tracking-experiments.md
block tracking-experiments
on 'python experiments.py 2>/dev/null'

stage model.py le-h449zbxt/a-change.md
block a-change
on 'dvc repro'
on 'dvc metrics diff v1'
on 'git add . && git commit -qm "lapse model v2: balanced class weights" && python log_run.py'
on 'python champion.py'

block going-back
on 'git checkout -q v1 && dvc checkout'
on 'python -c "import json; print(json.load(open(\"models/lapse.json\"))[\"data_sha256\"])"'
on 'md5sum models/lapse.joblib && grep -A2 "path: models/lapse.joblib" dvc.lock | grep "md5: "'
on 'git checkout -q main && dvc checkout'

quiet lab exec "setsid env $($F block $L7/the-page.md 'MLFLOW_SERVER_ENABLE_JOB_EXECUTION=false mlflow server --backend-store-uri sqlite:///mlflow.db --host 127.0.0.1 --port 5000 --workers 1') > /tmp/mlflow-server.log 2>&1 < /dev/null & for i in \$(seq 60); do curl -s -o /dev/null http://127.0.0.1:5000/health && break; sleep 1; done"
block the-page
on 'curl -s "http://127.0.0.1:5000/api/2.0/mlflow/registered-models/get?name=lapse" | python -m json.tool | grep -E "\"(name|version|alias|status)\""'
on 'ps -o pid,rss,args -u ana | grep -E "mlflow server|uvicorn" | grep -v grep | cut -c1-72'
quiet lab exec 'pkill -f "[m]lflow server" || true'
