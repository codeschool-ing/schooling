#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: inputs.py, shapes.py,
# check-in.py, check-out.py, retry.py (from its annotated example), draft.py
# and the data files are exactly what the lessons print; allowed-hosts.json
# and ask.py come from lessons 5 and 1. It prints each command after a
# prompt, ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the input rules, the schema, the six requests and the
# seven replies in data/outputs.jsonl, which no model produced; `guard retry`
# replays them in place of a model's attempts.
#
# THE MODEL: the "draft" block is llama3.2:3b (a80c4f17acd5), served by
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

block rules
on 'guard inputs > data/inputs.jsonl'
on 'cat data/input-rules.json'
on 'head -1 data/inputs.jsonl'

block checkin
on 'guard check-in data/inputs.jsonl; echo "exit $?"'

block schema
on 'cat data/output-schema.json'

block out12
on 'guard check-out data/outputs.jsonl --id out-1 --show'
on 'guard check-out data/outputs.jsonl --id out-2 --show'

block outall
on 'guard check-out data/outputs.jsonl'
on 'cat data/allowed-hosts.json'

block retry
on 'guard retry out-3 out-1; echo "exit $?"'
on 'guard retry out-2 out-7; echo "exit $?"'

block draft
on 'guard draft in-1; echo "exit $?"'
