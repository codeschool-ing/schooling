#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ai-security, as a script that
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
# help centre, the answers in data/answers.jsonl, the registry snapshot and the
# suggested packages were WRITTEN BY THE COURSE; no model wrote the answers.
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

block grounding
on 'ls data/helpdesk'
on 'cat data/helpdesk/hc-refunds.md'
on 'head -2 data/answers.jsonl'
on 'guard ground data/answers.jsonl; echo "exit $?"'
on 'grep a6 data/answers.jsonl'
on 'cat data/helpdesk/hc-payouts.md'

block packages
on 'cat data/suggested-deps.txt'
on 'guard deps data/suggested-deps.txt; echo "exit $?"'
