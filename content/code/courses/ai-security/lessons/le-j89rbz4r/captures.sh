#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: detect.py,
# moderation.py, filter.py, moderate.py and the three data files are exactly
# what the lesson prints. It prints each command after a prompt,
# ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the system prompt with its harmless canary marker,
# the six replies (no model produced them) and the stand-in moderation word
# list, which is not a model. No model is called in this lesson.
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

block layers
on 'cat data/pipeline-outputs.jsonl'
on 'guard filter data/pipeline-outputs.jsonl'

block allow
on "guard moderate 'Shut up, you clown'"
on "guard moderate 'Shut up, you cl0wn'"

block canary
on 'cat data/system-prompt.txt'

block skip
on 'guard filter data/pipeline-outputs.jsonl --skip canary'
