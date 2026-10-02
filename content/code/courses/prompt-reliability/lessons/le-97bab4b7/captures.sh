#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of prompt-reliability, as a script
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

block problem
on 'cat prompts/v4-only-json.txt'
on 'head -n 3 cases/attacks.jsonl'
on 'pl run prompts/v4-only-json.txt cases/attacks.jsonl --out runs/v4-attacks.jsonl'
on 'pl check runs/v4-attacks.jsonl --failures'
on 'pl show runs/v4-attacks.jsonl a10'
on 'pl show runs/v4-attacks.jsonl a04'

block layers
on 'diff prompts/v4-only-json.txt prompts/v5-tagged.txt'
on 'pl run prompts/v5-tagged.txt cases/attacks.jsonl --samples 5 --out runs/v5-attacks.jsonl'
on 'pl check runs/v5-attacks.jsonl --failures'
on 'grep -n "^LEAK" promptlab/standin.py'
on 'pl render prompts/v5-tagged.txt --cases cases/attacks.jsonl --case a08'
on 'pl render prompts/v6-escaped.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'
on 'pl run prompts/v6-escaped.txt cases/attacks.jsonl --samples 5 --out runs/v6-attacks.jsonl'
on 'pl check runs/v6-attacks.jsonl --failures'
on 'pl show runs/v6-attacks.jsonl a03'
on 'pl show runs/v6-attacks.jsonl a02 --sample 3'

block scan
on 'pl scan cases/attacks.jsonl'

block canary
on 'head -n 1 prompts/v7-canary.txt'
on 'pl run prompts/v7-canary.txt cases/attacks.jsonl --samples 5 --out runs/v7-attacks.jsonl'
on 'pl check runs/v7-attacks.jsonl --canary FOLIO-7Q2X --failures'
on 'pl show runs/v7-attacks.jsonl a04 --sample 2'
on 'pl show runs/v7-attacks.jsonl a05'
