#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of prompt-reliability, as a script
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

block confound
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl'
on 'pl run prompts/v7-prose.txt cases/all.jsonl --set temperature=0.8 --out runs/v7-warm.jsonl'
on 'pl compare runs/v6.jsonl runs/v7-warm.jsonl'
on 'head -n 1 runs/v7-warm.jsonl'

block style
on 'diff prompts/v6-escaped.txt prompts/v7-prose.txt'
on 'pl run prompts/v7-prose.txt cases/all.jsonl --out runs/v7.jsonl'
on 'pl check runs/v6.jsonl'
on 'pl check runs/v7.jsonl'
on 'pl compare runs/v6.jsonl runs/v7.jsonl'
on 'pl compare runs/v6.jsonl runs/v7.jsonl --answers'
on "pl check runs/v6.jsonl --failures | grep 'not JSON'"
on "pl check runs/v7.jsonl --failures | grep 'not JSON'"
on 'pl show runs/v6.jsonl t26'
on 'pl show runs/v7.jsonl t26'

block sign
on "python3 -c 'from promptlab.cli import sign_test; [print(n, sign_test(n, 0)) for n in range(1, 9)]'"
on "python3 -c 'from promptlab.cli import sign_test; [print(n, 1, round(sign_test(n, 1), 3)) for n in range(5, 10)]'"

block formats
on "echo 'Order 4471: 2 paperbacks, paid 24.50 on 2026-08-03, sent by courier.' | pl tokens -"
on "echo '{\"order\": \"4471\", \"items\": 2, \"format\": \"paperback\", \"paid\": 24.50, \"date\": \"2026-08-03\", \"sent\": \"courier\"}' | pl tokens -"
on "printf 'order,items,format,paid,date,sent\n4471,2,paperback,24.50,2026-08-03,courier\n' | pl tokens -"
