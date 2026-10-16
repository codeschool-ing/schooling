#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of delivery-metrics, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and ../../lab/check.py says whether
# the lesson still quotes it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# The programs are read out of the lessons' own prose by lab/extract.py:
# billing.py from lesson 1, growth.py from this one.
#
# STAGED, and not typed in the lesson: ~/delivery as lesson 1 leaves it, with
# billing.py saved and run once.
#
# Recorded with Python 3.13, TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COURSE=$HERE/../..
lab() { bash "$COURSE/lab.sh" "$@"; }
put() { python3 "$COURSE/lab/extract.py" "$2" "$1" | lab exec "cat > '$1'"; }
on() { printf 'ana@laptop:~/delivery$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab up >/dev/null
lab reset
put billing.py "$COURSE/lessons/le-zz75x0ba"
lab exec 'python3 billing.py >/dev/null'

put growth.py "$HERE"
block growth
on 'python3 growth.py 30 0 0'
on 'python3 growth.py 30 0.2 0.2'
on 'python3 growth.py 30 0.1 0.4'
