#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: standin.py, score.py,
# shortlist.py, fairness.py, counterfactual.py and the profiles are exactly
# what the lesson prints. It prints each command after a prompt,
# ana@lab:~/guard$, followed by what it printed.
#
# WRITTEN BY THE COURSE: the sixteen profiles, the stand-in scorer (which is
# not a model) and the counts shortlist.py writes the two tables from. No
# model is called in this lesson.
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

block profiles
on 'head -4 data/profiles.jsonl'

block score
on 'guard score data/profiles.jsonl'

block measuring
on 'guard shortlist v1 > data/shortlist-v1.csv'
on 'head -3 data/shortlist-v1.csv'
on 'guard fairness data/shortlist-v1.csv --group region'

block v2
on 'guard shortlist v2 > data/shortlist-v2.csv'
on 'guard fairness data/shortlist-v2.csv --group region'

block counterfactual
on 'guard counterfactual data/profiles.jsonl'
