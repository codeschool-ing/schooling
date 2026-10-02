#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of prompt-reliability, as a script
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

block templates
on 'cat prompts/reply.txt'
on 'pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio; echo "exit status $?"'
on 'pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English'

block unused
on 'pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English --var tone=warm > /dev/null'

block values
on 'grep a08 cases/attacks.jsonl'
on 'pl render prompts/v5-tagged.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'
on 'diff prompts/v5-tagged.txt prompts/v6-escaped.txt'
on 'pl render prompts/v6-escaped.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'

block reuse
on 'pl render prompts/v6-escaped.txt --cases cases/dev.jsonl --case t02 | tail -n 3'
on 'pl run prompts/v6-escaped.txt cases/dev.jsonl --out runs/v6.jsonl'
on 'head -n 3 prompts/v17-static-first.txt'
on 'pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/v17.jsonl'
on 'sha256sum prompts/v17-static-first.txt | cut -c1-8'
on 'pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/v17-hot.jsonl --set temperature=0.8'
