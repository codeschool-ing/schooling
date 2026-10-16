#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of machine-learning, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was pasted from running it, by lab/paste.py:
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh > /tmp/l21.txt
#   python3 ../../lab/paste.py --check . /tmp/l21.txt
#
# STAGED, not typed: ~/ml as lesson 1 leaves it, and feira.py as lesson 2
# prints it. Every program is read out of the section that prints it.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, scikit-learn 1.9.1, 4 cores,
# TZ=America/Sao_Paulo, on 2026-10-16.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/../../lab/capture.sh"

lab up >/dev/null
lab reset
save "$HERE/../le-q0dyd8be/a-module.md" feira.py
save "$HERE/../le-2rz4a24n/a-pipeline.md" churn_model.py
save "$HERE/saving.md" stored.py
save "$HERE/saving.md" save_model.py
save "$HERE/loading.md" load_model.py
save "$HERE/the-api.md" app.py
save "$HERE/calling-it.md" row.py
save "$HERE/same-answer.md" compare.py

block save-model
sess <<'CMDS'
python save_model.py
ls -l models
CMDS

block card
on 'cat models/churn-2025-12.json'

block load-model
on 'python load_model.py'

block elsewhere
sess <<'CMDS'
cd /tmp
python -c 'import joblib; joblib.load("/home/ana/ml/models/churn-2025-12.joblib")'
CMDS

# The server runs in a terminal of its own in the lesson. Here it runs in the
# background, and what that terminal showed is its log, printed under the two
# lines typed there.
quiet 'setsid uvicorn app:app > uvicorn.log 2>&1 < /dev/null & echo $! > uvicorn.pid'
quiet 'until grep -q "startup complete" uvicorn.log; do sleep 0.2; done'

block calls
sess <<'CMDS'
curl -s localhost:8000/health | jq -c
python row.py C00007 2026-03-01 > c00007.json
cat c00007.json
curl -s localhost:8000/score -H 'content-type: application/json' -d @c00007.json | jq -c
python row.py C00035 2026-03-01 | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c
CMDS

block refusals
sess <<'CMDS'
jq '.age = "forty"' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c '.detail[] | [.loc[1], .msg]'
jq 'del(.rating_90d)' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c '.detail[] | [.loc[1], .msg]'
jq '.plan = "daily"' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c
CMDS

block uvicorn
printf 'ana@lab:~$ cd ~/ml\nana@lab:~/ml$ uvicorn app:app\n'
lab exec 'cat uvicorn.log'

block log
on 'cat scores.jsonl'

block compare
on 'python compare.py'

quiet 'kill $(cat uvicorn.pid)'
