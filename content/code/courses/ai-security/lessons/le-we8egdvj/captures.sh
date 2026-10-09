#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: cost.py, daylog.py,
# budget.py and data/prices.json are exactly what this lesson prints; ask.py
# is lesson 1's. It prints each command after a prompt, ana@lab:~/guard$,
# followed by what it printed.
#
# WRITTEN BY THE COURSE: the prices in data/prices.json, which are no
# provider's, and the day of calls daylog.py writes by a rule.
#
# THE MODEL: the two replies counted in the "cost" block are llama3.2:3b
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

block cost
on 'guard cost "Explain to a new client how payment works on a freelance marketplace that holds the money until the job is delivered."'
on 'guard cost "Explain to a new client how payment works on a freelance marketplace that holds the money until the job is delivered." --max-tokens 60'

block none
on 'guard daylog'
on 'guard budget data/day-usage.jsonl'

block ceiling
on 'guard budget data/day-usage.jsonl --day-cents 2000'

block both
on 'guard budget data/day-usage.jsonl --user-tokens 100000 --day-cents 2000'
