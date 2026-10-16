#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine of lesson 1 with every tool of
# the course installed; lesson 1's two files of "The box office" and this
# lesson's measure.py, twenty.sh, mix.js, mix-expected.js and omission.py,
# copied out of the sections that show them rather than pasted into nano. The
# server runs in the background, where the lesson has the student run it in a
# second terminal. The database is seeded afresh before every run that books
# seats, so each run starts with the same seats sold.
#
# The pause in "Coordinated omission" is typed by the student as a line of
# its own; here it is the same line. Every timing differs on every run, and
# the recording computer's four processors were shared with other work, so
# its numbers are noisier than a quiet machine's.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l08
shown "$L1/the-boxoffice.md" "$HERE_DIR/the-mean.md" "$HERE_DIR/by-hand.md" \
  "$HERE_DIR/throughput-and-errors.md" "$HERE_DIR/coordinated-omission.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

block measure
run 'python3 measure.py 8 10 0.2'

quiet 'python3 seed.py'
block twenty
run 'bash twenty.sh > times.txt'
run "paste -sd' ' times.txt"
run "sort -n times.txt | paste -sd' '"

block sweep
run 'for w in 1 2 4 8 16 32; do python3 measure.py $w 5 | sed -n "1p;4p"; done'

quiet 'python3 seed.py'
block k6-mix
run 'k6 run mix.js 2>&1 | grep -E "http_req_(duration|failed)|expected_resp|http_reqs"'
quiet 'python3 seed.py'
block k6-expected
run 'k6 run mix-expected.js 2>&1 | grep -E "http_req_(duration|failed)|expected_resp|http_reqs"'

block closed
run "(sleep 3; pkill -STOP -f '^python3 app.py\$'; sleep 1; pkill -CONT -f '^python3 app.py\$') & python3 omission.py closed"
block open
run "(sleep 3; pkill -STOP -f '^python3 app.py\$'; sleep 1; pkill -CONT -f '^python3 app.py\$') & python3 omission.py open"
stop
