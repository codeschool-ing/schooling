#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: ground.py, deps.py,
# answer.py and every data file below are exactly what the lesson prints. It
# prints each command after a prompt, ana@lab:~/guard$, then what it printed.
#
# WRITTEN BY THE COURSE: the help centre, the six answers in
# data/answers.jsonl, the registry snapshot and the suggested packages. No
# model wrote those answers; each was written to trip one rule.
#
# THE MODEL: the "live" and "realdeps" blocks are replies of llama3.2:3b
# (a80c4f17acd5), served by Ollama 0.40.0, captured on 2026-10-07 on a
# machine with no graphics card, at temperature 0 and seed 1 unless the
# command says otherwise. It needs `ollama serve` running with that model.
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
Q="Which Python packages would I install to generate a Pix QR code for a Brazilian payment, and to validate a CPF? Reply with package names only, one per line, nothing else."

block helpdesk
on 'ls data/helpdesk'
on 'cat data/helpdesk/hc-refunds.md'

block grounding
on 'head -2 data/answers.jsonl'
on 'guard ground data/answers.jsonl; echo "exit $?"'

block a6
on 'grep a6 data/answers.jsonl'
on 'cat data/helpdesk/hc-payouts.md'

block live
on 'guard answer r1 "How long do I have to ask for a refund?" > data/live.jsonl'
on 'guard answer r2 "What fee does Tarefa charge?" >> data/live.jsonl'
on 'guard answer r3 "Can I pay in instalments?" >> data/live.jsonl'
on 'guard answer r4 "When are freelancers paid?" >> data/live.jsonl'
on 'cat data/live.jsonl'
on 'guard ground data/live.jsonl; echo "exit $?"'

block packages
on 'cat data/suggested-deps.txt'
on 'guard deps data/suggested-deps.txt; echo "exit $?"'

block realdeps
on "guard ask \"$Q\" > data/model-deps.txt"
on 'cat data/model-deps.txt'
on 'guard deps data/model-deps.txt; echo "exit $?"'
on "guard ask \"$Q\" --temperature 0.8 --seed 2"
