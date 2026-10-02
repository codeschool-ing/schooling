#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of prompt-reliability, as a script
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

block cache
on 'grep -n -A6 "It also keeps a prompt cache" promptlab/model.py'
on 'grep -n "^BLOCK\|^MINIMUM" promptlab/model.py'
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --set cache=on --out runs/short.jsonl'
on 'pl cost runs/short.jsonl | head -n 5'

block order
on 'head -n 4 prompts/v17-static-first.txt'
on 'head -n 6 prompts/v17-message-first.txt'
on 'pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/static.jsonl'
on 'pl run prompts/v17-message-first.txt cases/dev.jsonl --out runs/first.jsonl'
on 'pl cost runs/static.jsonl'
on 'pl cost runs/first.jsonl'

block arithmetic
on 'grep cache prices.json'
on 'diff <(tail -n +3 prompts/v17-static-first.txt) prompts/v8-guide.txt && echo same template'
on 'pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/plain.jsonl'
on 'pl cost runs/plain.jsonl'
on 'grep -n "^LATENCY" promptlab/model.py'
on 'pl latency runs/plain.jsonl'
on 'pl latency runs/static.jsonl'

block invalidation
on 'pl compare runs/plain.jsonl runs/static.jsonl'
on 'pl compare runs/static.jsonl runs/first.jsonl'
on 'pl compare runs/static.jsonl runs/first.jsonl --answers'
on 'pl check runs/static.jsonl'
on 'pl check runs/first.jsonl'
on 'pl show runs/static.jsonl t18'
on 'pl show runs/first.jsonl t18'
