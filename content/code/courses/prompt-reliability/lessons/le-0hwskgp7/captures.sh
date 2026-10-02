#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of prompt-reliability, as a script
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

block three
on 'pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3.jsonl'
on 'pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4.jsonl'
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'pl vote runs/v3.jsonl runs/v4.jsonl runs/v6.jsonl'
on "for r in v3 v4 v6; do pl check runs/\$r.jsonl --failures | awk '\$2 == \"json\" || \$2 == \"category\" {print \$1}'; done | sort | uniq -c"

block sampling
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --samples 5 --set temperature=0.8 --out runs/s5.jsonl'
on 'pl vote runs/s5.jsonl'
on 'pl show runs/s5.jsonl t37 --sample 0'
on 'pl show runs/s5.jsonl t37 --sample 1'

block cost
on 'pl cost runs/v6.jsonl'
on 'pl cost runs/s5.jsonl'
on 'pl cost runs/v3.jsonl'
on 'pl cost runs/v4.jsonl'
