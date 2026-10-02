#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of prompt-reliability, as a script
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

block pays
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl show runs/v1.jsonl t17'
on 'pl show runs/v2.jsonl t17'
on 'pl tokens prompts/v1-bare.txt'
on 'pl tokens prompts/v2-json.txt'
on 'pl latency runs/v1.jsonl'
on 'pl latency runs/v2.jsonl'

block contract
on 'sed -n 3,6p prompts/v2-json.txt'
on 'grep -n -A12 '"'"'elif c == "fields"'"'"' promptlab/cli.py'
on 'pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl'
on 'pl check runs/leaky.jsonl --failures | sed -n 9,11p'

block strict
on 'diff prompts/v2-json.txt prompts/v4-only-json.txt'
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl check runs/v4.jsonl --failures'
on 'pl compare runs/v2.jsonl runs/v4.jsonl'
on 'pl show runs/v4.jsonl t19'
on 'pl check runs/v2.jsonl --lenient'
on 'pl check runs/v4.jsonl --lenient'
on 'grep -n -A12 "^def parse" promptlab/cli.py'

block fails
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/retry.jsonl --samples 3'
on 'pl check runs/retry.jsonl --failures | grep json'
