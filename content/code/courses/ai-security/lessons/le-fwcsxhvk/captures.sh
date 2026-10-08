#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: minimise.py,
# summarise.py, restore.py, sensitive.py, the ticket and the purposes are
# exactly what the lesson prints; detect.py is lesson 5's and ask.py lesson
# 1's. It prints each command after a prompt, ana@lab:~/guard$, followed by
# what it printed.
#
# WRITTEN BY THE COURSE: the ticket (the people, CPFs and phone are
# invented) and the purpose.
#
# THE MODEL: the "reply" block is llama3.2:3b (a80c4f17acd5), served by
# Ollama 0.40.0, captured on 2026-10-07 on a machine with no graphics card,
# at temperature 0 and seed 1. It needs `ollama serve` running.
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

block who
on 'cat data/ticket-4471.json'

block purposes
on 'cat data/purposes.json'

block refuse
on 'guard minimise data/ticket-4471.json --purpose summarise-dispute; echo "exit $?"'
on 'ls outbox vault 2>&1'

block remove
on 'guard minimise data/ticket-4471.json --purpose summarise-dispute --sensitive remove'
on 'cat outbox/TK-4471.json'

block vault
on 'cat vault/TK-4471.json'

block reply
on 'guard summarise outbox/TK-4471.json --purpose summarise-dispute > reply-4471.txt'
on 'cat reply-4471.txt'
on 'guard restore vault/TK-4471.json reply-4471.txt; echo "exit $?"'

block sensitive
on "guard sensitive 'I was in hospital for a week with a kidney infection'"
on "guard sensitive 'I spent a week in bed with a fever and the doctor said rest'"
on "guard sensitive 'My son has autism and I can only work at night'"
