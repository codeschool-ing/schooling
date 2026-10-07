#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: modeval.py and
# data/forum.jsonl here, moderation.py and moderate.py from lesson 5, exactly
# as the lessons print them. It prints each command after a prompt,
# ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the sixty forum messages and their labels, and the
# stand-in moderation word list, which is not a moderation model. No model is
# called in this lesson.
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

block endpoint
on "guard moderate 'Shut up, you clown'"
on "guard moderate 'Deliver tomorrow or you will regret it'"
on "guard moderate 'Click here to claim your prize'"
on "guard moderate 'He called me an idiot in the chat, can a moderator look?'"

block measuring
on 'head -3 data/forum.jsonl'
on 'guard modeval data/forum.jsonl --category harassment --threshold 0.5 --show'

block spam
on 'guard modeval data/forum.jsonl --category spam --sweep'

block harassment
on 'guard modeval data/forum.jsonl --category harassment --sweep'

block lanes
on 'guard modeval data/forum.jsonl --category harassment --review 0.5 --block 0.85 --show'
