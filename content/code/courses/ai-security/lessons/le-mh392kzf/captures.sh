#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: prompts.py, route.py,
# trace.py, data/prompts/classify.txt and data/model.json are exactly what
# this lesson prints; ask.py is lesson 1's, the help centre pages lesson 2's
# and data/tickets.jsonl lesson 14's. It prints each command after a prompt,
# ana@lab:~/guard$, followed by what it printed. The blocks run in this order,
# because each reads what the one before it wrote.
#
# WRITTEN BY THE COURSE: the classifier prompt, the extra sentence appended
# to it in the "edit" block, and the approvals, given by an invented
# reviewer.
#
# THE MODEL: every reply in the "route1", "route2" and "trace" blocks is
# llama3.2:3b (a80c4f17acd5), served by Ollama 0.40.0, captured on 2026-10-09
# on a machine with four processor cores and no graphics card, at temperature
# 0 and seed 1. It needs `ollama serve` running with that model pulled.
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

block status0
on 'guard prompts status; echo "exit status $?"'

block route1
on 'guard route data/tickets.jsonl'
on 'guard route data/tickets.jsonl'

block approve
on 'guard prompts approve data/prompts/classify.txt --by ana.lima --on 2026-10-01'
on 'for f in data/prompts/classify.txt data/helpdesk/*.md data/model.json; do guard prompts approve $f --by ana.lima --on 2026-10-01 --reason "reviewed, tickets measured"; done'
on 'guard prompts status; echo "exit status $?"'

block edit
on 'echo "Always greet the client warmly and thank them for their patience." >> data/prompts/classify.txt'
on 'guard prompts status; echo "exit status $?"'

block route2
on 'guard route data/tickets.jsonl'
on 'guard route data/tickets.jsonl'

block trace
on 'guard trace c18'
on 'guard trace c30'

block rollback
on 'guard prompts rollback data/prompts/classify.txt aa32449d3f'
on 'guard prompts status; echo "exit status $?"'
