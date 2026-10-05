#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-security, as a script that
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
# decisions in data/shortlist-v1.csv and shortlist-v2.csv were WRITTEN BY THE
# COURSE from the counts in guardlab/fairness.py; no model made them. The
# scores come from guardlab/standin.py, which is NOT A MODEL: it is a rule the
# course wrote, with a bonus for Southeastern CEPs put there on purpose, and its
# docstring says so. The profiles in data/profiles.jsonl are invented.
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

block sources
on 'head -4 data/profiles.jsonl'
on 'guard score data/profiles.jsonl'
on "sed -n '/^THRESHOLD/,\$p' guardlab/standin.py"

block measuring
on 'head -3 data/shortlist-v1.csv'
on 'guard fairness data/shortlist-v1.csv --group region'

block tradeoffs
on 'guard fairness data/shortlist-v2.csv --group region'

block counterfactual
on 'guard counterfactual data/profiles.jsonl'
