#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: kyc.py, cnpj.py,
# onboard.py, drift.py and the five data files are exactly what the lesson
# prints. It prints each command after a prompt, ana@lab:~/guard$, followed by
# what it printed.
#
# WRITTEN BY THE COURSE: the eight applications (the companies are
# invented; the CNPJ check-digit algorithm is the real one), the registry
# that stands in for the Receita Federal's public data, the policy, the tiers
# and the weekly usage. No model is called in this lesson.
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

block applications
on 'head -1 data/applications.jsonl'

block cnpj
on 'guard cnpj 19.384.756/0001-01'
on 'guard cnpj 19.384.756/0001-00'

block onboard
on 'guard onboard data/applications.jsonl --now 2026-09-30'

block usecases
on 'cat data/use-cases.json'

block ap03
on 'guard onboard data/applications.jsonl --now 2026-09-30 --id ap-03'

block ap02
on "grep ap-02 data/applications.jsonl"

block tiers
on 'cat data/tiers.json'

block drift
on 'guard drift p-docelar'
