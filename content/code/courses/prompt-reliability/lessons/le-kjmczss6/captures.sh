#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of prompt-reliability, as a script
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

block judge
on 'cat prompts/judge.txt'
on 'head -n 1 cases/pairs.jsonl'
on 'grep -nE "^(FIRST_SEAT|PER_CHARACTER)" promptlab/standin.py'

block measure
on 'pl judge cases/pairs.jsonl'
on "grep -c '\"human\": \"a\"' cases/pairs.jsonl"

block biases
on 'pl judge cases/pairs.jsonl --swap'
on "python3 -c 'import json; [print(p[\"id\"], p[\"human\"], len(p[\"a\"]), len(p[\"b\"])) for p in map(json.loads, open(\"cases/pairs.jsonl\"))]'"
on "grep '\"j16\"' cases/pairs.jsonl"
