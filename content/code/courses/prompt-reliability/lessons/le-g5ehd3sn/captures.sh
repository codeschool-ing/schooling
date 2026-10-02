#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of prompt-reliability, as a script
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

block correctness
on 'pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6-all.jsonl'
on 'pl confusion runs/v6-all.jsonl'
on 'grep h03 cases/all.jsonl'
on 'pl show runs/v6-all.jsonl h03'
on 'pl confusion runs/v6-all.jsonl --field urgency'

block format
on 'pl check runs/v6-all.jsonl'
on 'pl check runs/v6-all.jsonl --failures | grep json'
on 'pl show runs/v6-all.jsonl t26'

block tone
on 'cat checks/tone.json'
on 'pl tone runs/drafts.jsonl'
on 'pl show runs/drafts.jsonl t02'
on 'pl show runs/drafts.jsonl t03'

block safety
on 'pl show runs/drafts.jsonl t12'
on 'pl show runs/drafts.jsonl t09'

block many
on 'pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3-all.jsonl'
on 'pl check runs/v3-all.jsonl'
on 'pl confusion runs/v3-all.jsonl'
