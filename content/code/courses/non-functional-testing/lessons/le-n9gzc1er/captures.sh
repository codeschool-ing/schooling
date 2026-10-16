#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built with every tool of the
# course; lesson 1's two boxoffice files and this lesson's loadtest/hammer.py,
# copied out of the lessons by `shown` rather than pasted into nano; a fresh
# database from seed.py. The server runs in the background where the lesson
# has the student run it in a second terminal, and each `taskset` start of it
# in "Adding processors" is a restart in that terminal. The pauses between
# runs let the threads of a run that timed out finish before the next starts.
# Every timing differs on every run: the generator and the server share the
# recording computer's 4 processors with other work.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l02
shown "$L1/the-boxoffice.md" "$HERE_DIR/a-load-generator.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'
at '~/loadtest'

block steady
run 'python3 hammer.py http://127.0.0.1:8000/shows/990 10:5'
quiet 'sleep 5'
block spike
run 'python3 hammer.py http://127.0.0.1:8000/shows/990 10:3 200:2 10:3'
quiet 'sleep 10'
block stress
run 'python3 hammer.py http://127.0.0.1:8000/shows/990 40:2 80:2 120:2 160:2 200:2 240:2'
stop
quiet 'sleep 10'

at '~/boxoffice'
serve 'taskset -c 0 python3 app.py'
at '~/loadtest'
block scale-one
run 'taskset -c 2,3 python3 hammer.py http://127.0.0.1:8000/shows/990 20:2 40:2 60:2 80:2'
stop
quiet 'sleep 5'
at '~/boxoffice'
serve 'taskset -c 0,1 python3 app.py'
at '~/loadtest'
block scale-two
run 'taskset -c 2,3 python3 hammer.py http://127.0.0.1:8000/shows/990 20:2 40:2 60:2 80:2'
stop
