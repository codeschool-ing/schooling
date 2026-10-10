#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: search.py, assist.py,
# data/documents.jsonl and data/questions.jsonl are exactly what this lesson
# prints; ask.py is lesson 1's. It prints each command after a prompt,
# ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the eight documents, their owners, visibility and
# facts, for invented accounts, and the four questions.
#
# THE MODEL: every answer in the "prompt" and "filtered" blocks is llama3.2:3b
# (a80c4f17acd5), served by Ollama 0.40.0, captured on 2026-10-09 on a machine
# with four processor cores and no graphics card, at temperature 0 and seed 1.
# It needs `ollama serve` running with that model pulled. The other blocks call
# no model.
#
# Recorded with Python 3.12.3 (Ubuntu 24.04's), TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/home/ana}
mkdir -p "$HOME/.py"
ln -sf "$(command -v python3.12)" "$HOME/.py/python3"
export PATH=$HOME/.py:$PATH
GUARD_HOME=$HOME bash "$here/../../lab.sh" reset >/dev/null || exit 1
cd "$HOME/guard"
export PATH=$HOME/guard/bin:$PATH
on() { printf 'ana@lab:~/guard$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block search-all
on 'guard search "quote for my website"'

block prompt
on 'guard assist data/questions.jsonl --as ac-7Q2M --filter prompt'

block search-as
on 'guard search "quote for my website" --as ac-7Q2M'

block filtered
on 'guard assist data/questions.jsonl --as ac-7Q2M --filter search'

block audit
on 'guard search --audit data/questions.jsonl; echo "exit status $?"'

block staff
on 'guard search "account flagged for chargebacks" --as ac-7Q2M'
on 'guard search "account flagged for chargebacks" --as ana.lima --role staff'
