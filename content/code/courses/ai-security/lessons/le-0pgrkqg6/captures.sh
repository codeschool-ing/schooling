#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME, so nothing of yours
# is touched, and prints each command after a prompt, ana@lab:~/guard$,
# followed by what it printed.
#
# What is STAGED rather than typed: the whole of ~/guard, built by lab.sh. The
# tool calls in data/proposed-calls.jsonl were WRITTEN BY THE COURSE in place
# of what an agent would propose; no model was called.
#
# Recorded with Python 3.11, TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/var/tmp/ai-security}
mkdir -p "$HOME"
bash "$here/../../lab.sh" reset >/dev/null
cd "$HOME/guard"
export PATH=$HOME/guard/bin:$PATH
on() { printf 'ana@lab:~/guard$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

block privilege
on 'cat data/tools.json'
on 'cat data/proposed-calls.jsonl'
on 'guard gate data/proposed-calls.jsonl'

block confirm
on 'guard gate data/proposed-calls.jsonl --confirm c3'
on 'guard gate data/proposed-calls.jsonl --confirm c3 --by ana.lima | grep c3'

block isolation
on 'guard gate data/proposed-calls.jsonl --budget 4'
