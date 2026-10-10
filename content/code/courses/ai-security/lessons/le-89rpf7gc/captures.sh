#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of ai-security, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/guard with lab.sh reset under its own HOME (/home/ana), which
# builds it from the fences of the lessons themselves: runbooks.py, blast.py,
# incident.py, anpd.py, the two runbooks, data/access-payments.jsonl,
# data/incidents/INC-7.jsonl and data/holidays.txt are exactly what this
# lesson prints; data/alerts.json is lesson 22's and data/keys.json lesson
# 17's. It prints each command after a prompt, ana@lab:~/guard$, followed by
# what it printed.
#
# WRITTEN BY THE COURSE: the incident. The payments service's access log, the
# addresses in it (203.0.113.45 is from a range reserved for documentation),
# the timeline, the people in it and the note added in the "timeline" block
# are invented, and so are the runbooks. The holidays are Brazil's national
# ones for the end of 2026. No model is called in this lesson.
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

block runbooks
on 'guard runbooks; echo "exit status $?"'

block blast
on 'guard blast payments --leaked "2026-10-09 13:52" --ours 10.0.4.'

block timeline
on 'guard incident add INC-7 --at "2026-10-09 15:30" --kind note --by ana.lima "personal data affected: two payment records read; encarregado told"'
on 'guard incident show INC-7'

block anpd
on 'guard anpd --known 2026-10-09'
