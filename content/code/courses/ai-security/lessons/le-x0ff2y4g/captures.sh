#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: classify.py and
# data/tickets.jsonl are exactly what this lesson prints; ask.py is lesson
# 1's. It prints each command after a prompt, ana@lab:~/guard$, followed by
# what it printed.
#
# WRITTEN BY THE COURSE: the twelve tickets in data/tickets.jsonl and the
# queue a person would choose for each. The requests inside seven of them are
# the ordinary kind clients address to whoever reads a ticket.
#
# THE MODEL: every reply in this lesson is llama3.2:3b (a80c4f17acd5), served
# by Ollama 0.40.0, captured on 2026-10-09 on a machine with four processor
# cores and no graphics card, at temperature 0 and seed 1. It needs `ollama
# serve` running with that model pulled. Another machine may give other
# replies to the same requests; the lesson's argument is about the layouts,
# and the numbers it quotes are these.
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

block plain
on 'guard classify data/tickets.jsonl'

block roles
on 'guard classify data/tickets.jsonl --layout roles --show'

block schema
on 'guard classify data/tickets.jsonl --schema --show'
