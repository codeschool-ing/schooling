#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of prompt-reliability, as a script
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

block tokens
on 'pl tokens prompts/v4-only-json.txt'
on "echo 'They were charged twice for order 4471.' | pl tokens -"
on "echo '{\"summary\": \"They were charged twice for order 4471.\"}' | pl tokens -"
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --out runs/v4.jsonl'
on 'pl show runs/v4.jsonl t01'

block cap
on 'pl check runs/v4.jsonl'
on 'pl run prompts/v4-only-json.txt cases/dev.jsonl --set max_tokens=30 --out runs/cap30.jsonl'
on 'pl check runs/cap30.jsonl'
on "pl check runs/cap30.jsonl --failures | grep -c 'cut off at max_tokens'"
on 'pl show runs/cap30.jsonl t01'
on 'pl show runs/cap30.jsonl t35'

block words
on 'diff prompts/v4-only-json.txt prompts/v4-words.txt'
on 'pl run prompts/v4-words.txt cases/dev.jsonl --out runs/words.jsonl'
on 'pl show runs/v4.jsonl t37'
on 'pl show runs/words.jsonl t37'
on 'pl latency runs/v4.jsonl'
on 'pl latency runs/words.jsonl'
on 'pl compare runs/v4.jsonl runs/words.jsonl --answers'
on 'pl run prompts/v4-words.txt cases/dev.jsonl --set max_tokens=30 --out runs/words30.jsonl'
on 'pl check runs/words30.jsonl'

block setting
on 'pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4-all.jsonl'
on 'pl latency runs/v4-all.jsonl'
on 'pl run prompts/v9-confidence.txt cases/dev.jsonl --set max_tokens=50 --out runs/v9-50.jsonl'
on 'pl check runs/v9-50.jsonl --failures'
on 'pl show runs/v9-50.jsonl t37'
on 'pl show runs/v9-50.jsonl t24'
on 'pl run prompts/v9-confidence.txt cases/dev.jsonl --set max_tokens=100 --out runs/v9-100.jsonl'
on 'pl check runs/v9-100.jsonl'
on 'pl latency runs/v9-100.jsonl'
