#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of prompt-reliability, as a script
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

block time
on 'grep -n "^LATENCY" promptlab/model.py'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl'
on 'pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/v8.jsonl'
on 'pl latency runs/v2.jsonl'
on 'pl latency runs/v3.jsonl'
on 'pl latency runs/v8.jsonl'
on 'pl cost runs/v2.jsonl | head -n 5'
on 'pl cost runs/v3.jsonl | head -n 5'

block cost
on 'cat prices.json'
on 'pl cost runs/v3.jsonl'
on 'grep -n -A1 "Prices are whole cents" promptlab/cli.py'
on "python3 -c 'print(0.1 + 0.2)'"

block cutting
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl cost runs/v4.jsonl'
on 'pl compare runs/v3.jsonl runs/v4.jsonl'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --set max_tokens=30 --out runs/cap.jsonl'
on 'pl latency runs/cap.jsonl'
on 'pl check runs/cap.jsonl | tail -n 1'
on 'pl show runs/cap.jsonl t01'

block tradeoffs
on 'pl latency runs/v4.jsonl'
on 'pl check runs/v4.jsonl --failures | tail -n 6'
