#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of prompt-reliability, as a script
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

block log
on "git log --format='%h %ad %s' --date=short -- prompts/triage.txt"
on 'git log -1 --format=%B 31a6a59'

block evidence
on 'git show 31a6a59:prompts/triage.txt > runs/plain.txt'
on 'pl run runs/plain.txt cases/dev.jsonl --out runs/plain.jsonl'
on 'pl run prompts/triage.txt cases/dev.jsonl --out runs/dev.jsonl'
on 'pl compare runs/plain.jsonl runs/dev.jsonl'

block failure
on 'pl log'
on 'pl check runs/plain.jsonl'
on 'pl show runs/plain.jsonl t04'

block card
on 'for s in dev holdout attacks pasted; do pl run prompts/triage.txt cases/$s.jsonl --out runs/$s.jsonl > /dev/null; printf "%-8s" $s; pl check runs/$s.jsonl | tail -n 1; done'
on 'pl check runs/dev.jsonl --failures | tail -n 4'
on 'pl cost runs/dev.jsonl'
