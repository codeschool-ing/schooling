#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: gate.py, propose.py,
# the manifest and the seven proposals are exactly what the lesson prints;
# ask.py is lesson 1's. It prints each command after a prompt,
# ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the manifest with its session and the seven
# proposals in data/proposed-calls.jsonl; no model proposed those.
#
# THE MODEL: the "real" block is llama3.2:3b (a80c4f17acd5), served by
# Ollama 0.40.0, captured on 2026-10-07 on a machine with no graphics card,
# at temperature 0 and seed 1, in JSON mode. It needs `ollama serve` running.
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

block tools
on 'cat data/tools.json'

block privilege
on 'cat data/proposed-calls.jsonl'
on 'guard gate data/proposed-calls.jsonl'

block real
on 'guard propose "Job 4471 was never delivered. I paid R$ 1.200,00 and I want my money back." > data/real-calls.jsonl'
on 'cat data/real-calls.jsonl'
on 'guard gate data/real-calls.jsonl'
on 'guard propose "Where is my order 4471?" | guard gate /dev/stdin'

block confirm
on 'guard gate data/proposed-calls.jsonl --confirm c3'
on 'guard gate data/proposed-calls.jsonl --confirm c3 --by ana.lima | grep c3'

block isolation
on 'guard gate data/proposed-calls.jsonl --budget 4'
