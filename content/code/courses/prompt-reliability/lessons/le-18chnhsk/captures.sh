#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of prompt-reliability, as a script
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

block order
on 'diff prompts/v6-escaped.txt prompts/v18-order.txt'
on 'grep -n "^FIRST_LISTED" promptlab/standin.py'
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'pl run prompts/v18-order.txt cases/all.jsonl --out runs/order.jsonl'
on 'pl compare runs/v6.jsonl runs/order.jsonl --answers'
on "grep -E '\"(t37|h07|h15|h28)\"' cases/all.jsonl | grep -o '\"category\": \"[a-z]*\"'"
on 'pl compare runs/v6.jsonl runs/order.jsonl'
on 'pl show runs/order.jsonl t04'

block leading
on 'diff prompts/v6-escaped.txt prompts/v18-leading.txt'
on 'grep -n "^LEADING_PULL" promptlab/standin.py'
on 'pl run prompts/v18-leading.txt cases/all.jsonl --out runs/leading.jsonl'
on 'pl compare runs/v6.jsonl runs/leading.jsonl --answers'
on "grep -E '\"(t19|t23|t33|h10|h13|h16|h19|h20)\"' cases/all.jsonl | grep -o '\"category\": \"[a-z]*\"'"
on 'grep h20 cases/all.jsonl'

block balance
on 'grep -n "^EXAMPLE_PULL" promptlab/standin.py'
on "grep -o '\"category\": \"[a-z]*\"' prompts/v18-skewed.txt"
on "grep -o '\"category\": \"[a-z]*\"' prompts/v18-balanced.txt"
on 'pl run prompts/v18-skewed.txt cases/all.jsonl --out runs/skewed.jsonl'
on 'pl run prompts/v18-balanced.txt cases/all.jsonl --out runs/balanced.jsonl'
on 'pl compare runs/skewed.jsonl runs/balanced.jsonl --answers'
on 'pl check runs/skewed.jsonl'
on 'pl check runs/balanced.jsonl'

block names
on 'head -n 1 cases/names-a.jsonl cases/names-b.jsonl'
on 'pl run prompts/v6-escaped.txt cases/names-a.jsonl --out runs/names-a.jsonl'
on 'pl run prompts/v6-escaped.txt cases/names-b.jsonl --out runs/names-b.jsonl'
on 'pl compare runs/names-a.jsonl runs/names-b.jsonl --answers'
on 'pl compare runs/names-a.jsonl runs/names-b.jsonl'
on 'pl show runs/names-a.jsonl n06'
on 'pl show runs/names-b.jsonl n06'
