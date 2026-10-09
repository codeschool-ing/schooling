#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: memory.py and
# data/conversations.jsonl are exactly what this lesson prints; ask.py is
# lesson 1's, detect.py lesson 11's and minimise.py lesson 12's. It prints each
# command after a prompt, ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the three messages of an invented client in
# data/conversations.jsonl. The CPF has valid check digits on purpose, as in
# lesson 11, and belongs to nobody; the phone number is invented.
#
# THE MODEL: the proposals in the "learn" block are llama3.2:3b (a80c4f17acd5),
# served by Ollama 0.40.0, captured on 2026-10-09 on a machine with four
# processor cores and no graphics card, at temperature 0 and seed 1, under a
# JSON Schema. It needs `ollama serve` running with that model pulled. The
# other blocks call no model; they read what "learn" wrote, so the blocks run
# in this order.
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

block learn
on 'guard memory learn data/conversations.jsonl --as ac-7Q2M'

block show
on 'guard memory show --as ac-7Q2M --now 2026-03-21'
on 'guard memory show --as ac-0Z5Q --now 2026-03-21'

block expiry
on 'guard memory show --as ac-7Q2M --now 2026-07-01'
on 'wc -l < data/memory/ac-7Q2M.jsonl'
on 'guard memory sweep --now 2026-07-01'
on 'wc -l < data/memory/ac-7Q2M.jsonl'

block forget
on 'guard memory forget m4 --as ac-7Q2M'
on 'guard memory show --as ac-7Q2M --now 2026-07-01'
on 'guard memory forget m4 --as ac-7Q2M; echo "exit status $?"'
