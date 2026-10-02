#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of prompt-reliability, as a script
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

block length
on 'cat -n prompts/v2-long.txt'
on 'pl tokens prompts/v2-json.txt'
on 'pl tokens prompts/v2-long.txt'
on 'cat prices.json'
on 'pl run prompts/v2-json.txt cases/dev.jsonl --out runs/v2.jsonl'
on 'pl run prompts/v2-long.txt cases/dev.jsonl --out runs/long.jsonl'
on 'pl cost runs/v2.jsonl'
on 'pl cost runs/long.jsonl'

block contradictions
on 'grep -n -e brief -e detail prompts/v2-long.txt'
on 'grep t17 cases/dev.jsonl'
on 'pl show runs/v2.jsonl t17'
on 'pl show runs/long.jsonl t17'
on 'pl latency runs/v2.jsonl'
on 'pl latency runs/long.jsonl'

block lint
on 'pl lint prompts/v2-long.txt'
on 'pl lint prompts/v2-json.txt'
on "printf 'Keep the summary to one line.\\nLeave nothing out of the summary.\\n' | pl lint /dev/stdin"

block cutting
on 'cat prompts/v2-json.txt'
on 'pl check runs/long.jsonl'
on 'pl check runs/v2.jsonl'
on 'pl compare runs/long.jsonl runs/v2.jsonl'
on 'pl compare runs/long.jsonl runs/v2.jsonl --answers'
on 'pl show runs/v2.jsonl t08'
on 'pl show runs/long.jsonl t08'
