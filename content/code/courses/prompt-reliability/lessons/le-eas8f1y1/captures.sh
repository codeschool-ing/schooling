#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of prompt-reliability, as a script
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

block pile
on 'cat -n prompts/v8-rules.txt'
on 'pl lint prompts/v8-rules.txt'
on 'grep t22 cases/all.jsonl'

block guide
on 'cat -n prompts/v8-guide.txt'
on 'pl lint prompts/v8-guide.txt'
on 'pl tokens prompts/v8-rules.txt'
on 'pl tokens prompts/v8-guide.txt'

block measure
on 'wc -l cases/all.jsonl'
on 'pl run prompts/v8-rules.txt cases/all.jsonl --out runs/rules.jsonl'
on 'pl run prompts/v8-guide.txt cases/all.jsonl --out runs/guide.jsonl'
on 'pl check runs/rules.jsonl'
on 'pl check runs/guide.jsonl'
on 'pl compare runs/rules.jsonl runs/guide.jsonl'
on 'pl compare runs/rules.jsonl runs/guide.jsonl --answers'
on 'pl show runs/rules.jsonl t22'
on 'grep h03 cases/all.jsonl'
on 'pl check runs/guide.jsonl --failures | grep -e h03 -e h22'

block reader
on 'grep h01 cases/all.jsonl'
on 'grep -n refund prompts/v8-rules.txt'
on 'grep -n "goes to" prompts/v8-guide.txt'
on 'pl check runs/rules.jsonl --failures | grep h01'
