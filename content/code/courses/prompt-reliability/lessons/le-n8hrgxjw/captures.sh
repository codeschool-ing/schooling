#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of prompt-reliability, as a script
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

block scores
on "grep -A1 '^NEXT' promptlab/sample.py"
on 'pl sample'

block temperature
on 'pl sample --temperature 0.2'
on 'pl sample --temperature 1.5'

block cut
on 'pl sample --top-k 3'
on 'pl sample --top-p 0.9'
on "sed -n '/^def distribution/,/return \\[/p' promptlab/sample.py"
on 'pl sample --temperature 1.5 --top-p 0.9'

block task
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --out runs/t0.jsonl'
on 'pl check runs/t0.jsonl'
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=1 --out runs/t1.jsonl'
on 'pl check runs/t1.jsonl'
on "pl check runs/t1.jsonl --failures | grep '^t08'"
on "grep '\"t08\"' cases/dev.jsonl"
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.2 --out runs/t02.jsonl'
on 'pl check runs/t02.jsonl'
