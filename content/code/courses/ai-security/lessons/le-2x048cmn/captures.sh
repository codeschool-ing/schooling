#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: defences.py, rate.py,
# ci.sh, data/suite.json and data/candidates/classify.txt are exactly what
# this lesson prints; the programs the suite runs are those of lessons 13 to
# 21, the classifier prompt lesson 20's and data/tickets.jsonl lesson 14's.
# It prints each command after a prompt, ana@lab:~/guard$, followed by what
# it printed. The blocks run in this order, because "suite2" reads the
# approvals "approve" wrote.
#
# WRITTEN BY THE COURSE: the suite, its two known failures with their tickets
# and dates, the candidate prompt's extra sentence, the ceiling of 40% and the
# approvals, given by an invented reviewer.
#
# THE MODEL: every reply counted in the "once", "rate" and "ci" blocks is
# llama3.2:3b (a80c4f17acd5), served by Ollama 0.40.0, captured on 2026-10-09
# on a machine with four processor cores and no graphics card; "once" at
# temperature 0 and seed 1, the others at temperature 0.8 and seeds 1 to 10.
# It needs `ollama serve` running with that model pulled.
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

block suite1
on 'guard defences data/suite.json --now 2026-10-09; echo "exit status $?"'

block approve
on 'for f in data/prompts/classify.txt data/helpdesk/*.md data/model.json; do guard prompts approve $f --by ana.lima --on 2026-10-09 --reason "read in full"; done'

block suite2
on 'guard defences data/suite.json --now 2026-10-09; echo "exit status $?"'

block once
on 'guard rate data/prompts/classify.txt data/tickets.jsonl --runs 1 --temperature 0'
on 'guard rate data/candidates/classify.txt data/tickets.jsonl --runs 1 --temperature 0'

block rate
on 'guard rate data/prompts/classify.txt data/tickets.jsonl --runs 10'
on 'guard rate data/candidates/classify.txt data/tickets.jsonl --runs 10'

block ci
on 'CI_DATE=2026-10-09 bash ci.sh; echo "exit status $?"'
