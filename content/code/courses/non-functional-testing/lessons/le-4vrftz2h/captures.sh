#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: lesson 1's boxoffice, lesson 22's
# observed.py, and this lesson's probe.py and slow.py, copied out of the
# sections that show them; a fresh database from seed.py. The servers run in
# the background where the lesson has the student run them in the first
# terminal; stopping one stands for the student's Ctrl+C. The machine has no
# cron, so the crontab line is not run. Times, timings and request ids differ
# on every run; the prose quotes this one.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L22="$HERE_DIR/../le-kdp49ss1"

machine l23
shown "$L1/the-boxoffice.md" "$L22/observed.md" "$HERE_DIR/probe.md" "$HERE_DIR/schedule.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 observed.py > requests.log'

at '~/monitor'
block pass
run 'python3 probe.py; echo "exit $?"'
block down
stop
run 'python3 probe.py; echo "exit $?"'

at '~/boxoffice'
serve 'python3 observed.py > requests.log'
at '~/monitor'
block loop
run 'for i in 1 2 3; do python3 probe.py; sleep 5; done'
stop

at '~/boxoffice'
serve 'python3 slow.py > slow.log'
at '~/monitor'
block slow
run 'python3 probe.py; echo "exit $?"'
at '~/boxoffice'
block slow-log
run "jq -c 'select(.ms > 500)' slow.log"
stop

block clean
run "sqlite3 data/boxoffice.db \"SELECT show_id, seat, customer FROM bookings WHERE customer = 'synthetic-probe'\""
run "sqlite3 data/boxoffice.db \"DELETE FROM bookings WHERE customer = 'synthetic-probe'; SELECT changes()\""
