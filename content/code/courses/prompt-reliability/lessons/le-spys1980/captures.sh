#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of prompt-reliability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/triage with lab.sh reset under its own HOME, so nothing of
# yours is touched, and prints each command after a prompt, ana@lab:~/triage$,
# followed by what it printed.
#
# What is STAGED rather than typed: the whole of ~/triage, built by lab.sh,
# including every prompt file the lesson shows. The model is the lab's
# stand-in (promptlab/standin.py), NOT a language model; lab.sh's header says
# what that means and what in the lab was written by the course.
#
# Recorded with Python 3.11 and git 2.43, TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PAGER=cat GIT_PAGER=cat COLUMNS=100 PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/var/tmp/prompt-reliability}
mkdir -p "$HOME"
bash "$here/../../lab.sh" reset
cd "$HOME/triage"
export PATH=$HOME/triage/bin:$PATH
on() { printf 'ana@lab:~/triage$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block stated
on 'grep -n confidence prompts/v9-confidence.txt'
on 'grep -n -A6 "^def confidence" promptlab/standin.py'
on 'pl run prompts/v9-confidence.txt cases/all.jsonl --out runs/v9.jsonl'
on 'pl check runs/v9.jsonl'
on 'grep h04 cases/all.jsonl'
on 'pl show runs/v9.jsonl h04'

block reliability
on 'pl calibrate runs/v9.jsonl'

block thresholds
on 'pl run prompts/v9-confidence.txt cases/dev.jsonl --out runs/v9-dev.jsonl'
on 'pl run prompts/v9-confidence.txt cases/holdout.jsonl --out runs/v9-holdout.jsonl'
on 'pl calibrate runs/v9-dev.jsonl --thresholds'
on 'pl calibrate runs/v9-holdout.jsonl --thresholds'
