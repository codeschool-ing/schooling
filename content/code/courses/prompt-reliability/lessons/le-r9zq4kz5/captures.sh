#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of prompt-reliability, as a script
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

block testset
on 'head -n 1 cases/dev.jsonl'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl'
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl compare runs/v2.jsonl runs/v3.jsonl'
on 'pl compare runs/v4.jsonl runs/v3.jsonl'

block unit
on 'pl check runs/v2.jsonl --failures'
on 'grep -n "^CHECKS" promptlab/cli.py'

block easy
on 'head -n 3 cases/holdout.jsonl'
on 'pl check runs/v3.jsonl --failures'
on 'pl run prompts/v3-examples.txt cases/holdout.jsonl --out runs/v3-holdout.jsonl'
on 'pl check runs/v3-holdout.jsonl --failures'
on 'pl run prompts/v4-only-json.txt cases/holdout.jsonl --out runs/v4-holdout.jsonl'
on 'pl compare runs/v4-holdout.jsonl runs/v3-holdout.jsonl'

block contamination
on 'grep -n "Message:" prompts/v11-contaminated.txt'
on 'grep -E "\"t(21|23|37)\"" cases/dev.jsonl'
on 'pl run prompts/v11-contaminated.txt cases/dev.jsonl --out runs/v11.jsonl'
on 'pl compare runs/v3.jsonl runs/v11.jsonl'
on 'pl check runs/v11.jsonl --failures'
on 'pl run prompts/v11-contaminated.txt cases/holdout.jsonl --out runs/v11-holdout.jsonl'
on 'pl compare runs/v3-holdout.jsonl runs/v11-holdout.jsonl'

block flaky
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --out runs/hot-a.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --set temperature=1 --seed 7 --out runs/hot-b.jsonl'
on 'pl compare runs/hot-a.jsonl runs/hot-b.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --samples 5 --set temperature=1 --out runs/hot.jsonl'
on 'pl check runs/hot.jsonl'
on 'pl check runs/hot.jsonl --failures | grep -E "^t(05|14|21|23)[ #]"'
on 'pl check runs/hot.jsonl --failures'
