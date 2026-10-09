#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: flows.py, threats.py
# and the two data files are exactly what this lesson prints. It prints each
# command after a prompt, ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: data/flows.json, the diagram of an invented
# company's assistant, and data/threats.json, its register with the ratings
# and the gaps the lesson discusses. No model is called in this lesson.
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

block flows
on 'guard flows'

block flows-text
on 'guard flows --text'

block threats
on 'guard threats'

block open
on 'guard threats --open --text; echo "exit status $?"'
