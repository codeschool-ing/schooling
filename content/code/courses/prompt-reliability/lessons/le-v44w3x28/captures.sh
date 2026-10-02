#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of prompt-reliability, as a script
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

block lab
on 'ls'
on 'head -n 2 cases/dev.jsonl'
on 'wc -l cases/dev.jsonl'

block bare
on 'cat prompts/v1-bare.txt'
on 'pl run prompts/v1-bare.txt cases/dev.jsonl --out runs/v1.jsonl'
on 'pl show runs/v1.jsonl t01'
on 'pl check runs/v1.jsonl'

block json
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl check runs/v2.jsonl'
on 'pl show runs/v2.jsonl t03'
on 'pl show runs/v2.jsonl t06'

block examples
on 'cat prompts/v3-examples.txt'
on 'pl run prompts/v3-examples.txt cases/dev.jsonl --out runs/v3.jsonl'
on 'pl check runs/v3.jsonl --failures'
on 'pl compare runs/v2.jsonl runs/v3.jsonl'
on 'pl show runs/v3.jsonl t17'
on 'grep t37 cases/dev.jsonl'
on 'pl show runs/v3.jsonl t37'

block leak
on 'grep -n order prompts/v3-leaky.txt'
on 'pl run prompts/v3-leaky.txt cases/dev.jsonl --out runs/leaky.jsonl'
on 'pl check runs/leaky.jsonl'
on 'pl show runs/leaky.jsonl t04'

block cost
on 'pl tokens prompts/v2-json.txt'
on 'pl tokens prompts/v3-examples.txt'
