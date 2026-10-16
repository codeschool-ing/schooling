#!/usr/bin/env bash
# The terminal session quoted in lesson 14 of delivery-metrics, as a script
# that produces it.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, and ../../lab/check.py says whether
# the lesson still quotes it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# timeline.py is read out of this lesson's prose by lab/extract.py. It needs no
# other file: the timeline is written inside it.
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
put timeline.py "$HERE"
block timeline
on 'python3 timeline.py'
