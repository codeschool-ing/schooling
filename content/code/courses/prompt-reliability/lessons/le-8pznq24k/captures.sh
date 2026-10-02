#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of prompt-reliability, as a script
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

block why
on 'tail -n 3 prompts/v4-only-json.txt'
on 'pl render prompts/v4-only-json.txt --cases cases/pasted.jsonl --case p04 | tail -n 7 | cat -n'
on 'pl run prompts/v4-only-json.txt cases/pasted.jsonl --out runs/pasted-v4.jsonl'
on "grep '\"p01\"' cases/pasted.jsonl"
on 'pl show runs/pasted-v4.jsonl p01'

block backticks
on 'cat -n prompts/v5-backticks.txt'
on 'pl run prompts/v5-backticks.txt cases/pasted.jsonl --out runs/backticks.jsonl'
on 'pl check runs/backticks.jsonl --failures'
on 'pl render prompts/v5-backticks.txt --cases cases/pasted.jsonl --case p01 | tail -n 4 | cat -n'
on 'pl show runs/backticks.jsonl p01'
on 'pl show runs/backticks.jsonl p04'

block tagged
on 'diff prompts/v5-backticks.txt prompts/v5-tagged.txt'
on 'pl run prompts/v5-tagged.txt cases/pasted.jsonl --out runs/tagged.jsonl'
on 'pl check runs/tagged.jsonl --failures'
on 'pl compare runs/backticks.jsonl runs/tagged.jsonl'
on 'pl show runs/tagged.jsonl p04'

block a08
on "grep '\"a08\"' cases/attacks.jsonl"
on 'pl render prompts/v5-tagged.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'
on 'diff prompts/v5-tagged.txt prompts/v6-escaped.txt'
on 'pl render prompts/v6-escaped.txt --cases cases/attacks.jsonl --case a08 | tail -n 5'
on 'pl run prompts/v5-tagged.txt cases/attacks.jsonl --out runs/attacks-v5.jsonl'
on 'pl run prompts/v6-escaped.txt cases/attacks.jsonl --out runs/attacks-v6.jsonl'
on 'pl show runs/attacks-v5.jsonl a08'
on 'pl show runs/attacks-v6.jsonl a08'
