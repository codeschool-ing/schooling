#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of ai-security, as a script that
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
# system prompt in data/system-prompt.txt, its canary marker and the replies in
# data/pipeline-outputs.jsonl were WRITTEN BY THE COURSE; no model produced the
# replies.
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

block layers
on 'cat data/pipeline-outputs.jsonl'
on 'guard filter data/pipeline-outputs.jsonl'

block lists
on "guard moderate 'Shut up, you clown'"
on "guard moderate 'Shut up, you cl0wn'"
on 'guard check-in data/inputs.jsonl | grep in-4'

block canary
on 'cat data/system-prompt.txt'
on 'guard filter data/pipeline-outputs.jsonl --skip canary'
