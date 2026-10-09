#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: keyscan.py, keys.py,
# the repository under data/repo, the allow list and data/keys.json are
# exactly what this lesson prints; detect.py is lesson 11's. It prints each
# command after a prompt, ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the miniature repository and the key inventory of an
# invented company. EVERY KEY IN THEM IS FAKE: the sk-lab- values were made up
# for the lesson, and AKIAIOSFODNN7EXAMPLE is the example key in Amazon's own
# documentation. No model is called in this lesson.
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

block scan
on 'guard keyscan data/repo; echo "exit status $?"'

block allow
on 'guard keyscan data/repo --allow data/keyscan-allow.txt; echo "exit status $?"'

block prompt
on 'cat data/repo/prompts/support.txt'

block keys
on 'guard keys --now 2026-10-09; echo "exit status $?"'
