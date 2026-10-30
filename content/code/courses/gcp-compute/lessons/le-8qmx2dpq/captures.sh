#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-8qmx2dpq/captures.sh
#
# Everything here runs on the laptop, in a network namespace with only
# loopback: the Functions Framework serving a function on localhost, and
# arithmetic over egress prices.
#
# What is STAGED rather than typed:
#   - main.py and egress.py are read out of this lesson's own blocks, as the
#     student saves them;
#   - the Functions Framework is started in the background rather than in a
#     second terminal, and stopped by its pid at the end.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

mkdir -p seam
from_lesson "$HERE/portable-seams.md" seam/main.py > seam/main.py
from_lesson "$HERE/what-leaving-costs.md" egress.py > egress.py

block seam
cd seam || exit 1
setsid functions-framework --target=status --port=8080 >ff.log 2>&1 </dev/null &
FF=$!
for _ in $(seq 40); do curl -s -o /dev/null localhost:8080 && break; sleep 0.25; done
run 'curl -s localhost:8080/'
run 'curl -s -i localhost:8080/ | head -4'
kill "$FF"; wait "$FF" 2>/dev/null
cd .. || exit 1

block egress
run 'python3 egress.py 1 5 50'
