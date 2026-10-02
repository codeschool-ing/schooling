#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of prompt-reliability, as a script
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

block review
on 'cat prompts/review.txt'
on 'grep -n -A5 "^def review" promptlab/standin.py'

block t0
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'pl selfcheck runs/v6.jsonl'
on "grep -E '\"(h13|h15|h16|h19|h20|h28)\"' cases/all.jsonl | grep -o '\"category\": \"[a-z]*\"'"
on 'grep h27 cases/all.jsonl'
on 'pl show runs/v6.jsonl h27'

block sampled
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl'
on 'pl selfcheck runs/s5.jsonl | tail -n 4'
on 'pl selfcheck runs/s5.jsonl | grep -E "^(t37|h27)"'

block code
on 'pl check runs/v6.jsonl --failures | grep json'
