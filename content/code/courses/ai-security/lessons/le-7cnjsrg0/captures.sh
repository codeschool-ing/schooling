#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ai-security, as a script that
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
# scores come from guardlab/moderation.py, which is NOT A MODERATION MODEL: it
# is a list of English words with weights the course chose, answering in the
# shape a moderation endpoint answers in. The sixty messages in
# data/forum.jsonl and the labels beside them were WRITTEN BY THE COURSE; a
# person labelling real messages would disagree with some of them, and lesson
# 16 says so.
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

block endpoint
on "guard moderate 'Shut up, you clown'"
on "guard moderate 'Deliver tomorrow or you will regret it'"
on "guard moderate 'Click here to claim your prize'"
on "guard moderate 'He called me an idiot in the chat, can a moderator look?'"

block measuring
on 'head -3 data/forum.jsonl'
on 'guard modeval data/forum.jsonl --category harassment --threshold 0.5 --show'

block thresholds
on 'guard modeval data/forum.jsonl --category spam --sweep'
on 'guard modeval data/forum.jsonl --category harassment --sweep'
on 'guard modeval data/forum.jsonl --category harassment --review 0.5 --block 0.85 --show'
