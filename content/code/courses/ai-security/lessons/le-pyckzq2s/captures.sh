#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: register.py,
# review.py, data/ai-register.json, data/invoice-provider-c.json and
# data/changes/CHG-12.json are exactly what this lesson prints. It prints
# each command after a prompt, ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the register, its systems, staff and owners, the
# provider's bill (provider-c is lesson 19's invented provider) and the
# change with its evidence. No model is called in this lesson.
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

block register
on 'guard register --now 2026-10-09 --invoice data/invoice-provider-c.json; echo "exit status $?"'

block review
on 'guard review data/changes/CHG-12.json; echo "exit status $?"'
