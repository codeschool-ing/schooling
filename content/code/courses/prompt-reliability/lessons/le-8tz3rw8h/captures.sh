#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of prompt-reliability, as a script
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

block git
on 'git log --oneline -- prompts/triage.txt'
on 'git diff 9683448 931c548 -- prompts/triage.txt'

block version
on 'pl run prompts/triage.txt cases/dev.jsonl --out runs/now.jsonl'
on 'git show c8470c9:prompts/triage.txt > runs/triage-c8470c9.txt'
on 'pl run runs/triage-c8470c9.txt cases/dev.jsonl --out runs/c8470c9.jsonl'
on 'git diff c8470c9 03e1151 -- prompts/triage.txt | wc -l'
on 'pl run prompts/triage.txt cases/dev.jsonl --set temperature=0.8 --out runs/hot.jsonl'
on 'pl check runs/hot.jsonl'
on 'head -n 2 prompts/v17-static-first.txt'

block log
on 'pl log'
on 'git show 31a6a59'
on 'git show 31a6a59:prompts/triage.txt > runs/triage-31a6a59.txt'
on 'pl run runs/triage-31a6a59.txt cases/dev.jsonl --out runs/31a6a59.jsonl'
on 'pl show runs/31a6a59.jsonl t04'
on 'pl log cases/attacks.jsonl'

block regressions
on 'pl compare runs/c8470c9.jsonl runs/31a6a59.jsonl'
on 'pl compare runs/now.jsonl runs/hot.jsonl'
