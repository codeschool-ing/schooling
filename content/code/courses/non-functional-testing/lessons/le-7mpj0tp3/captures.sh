#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the machine, built with every tool of the
# course; lesson 1's two boxoffice files, lesson 2's loadtest/hammer.py and
# this lesson's loadtest/users.py, copied out of the lessons by `shown` rather
# than pasted into nano; a fresh database from seed.py. The server runs in the
# background where the lessons have the student run it in a second terminal.
# The pauses between runs let the requests of one run finish before the next.
# Every timing differs on every run: the generator and the server share the
# recording computer's 4 processors with other work.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L2="$HERE_DIR/../le-n9gzc1er"

machine l03
shown "$L1/the-boxoffice.md" "$L2/a-load-generator.md" "$HERE_DIR/virtual-users.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'
at '~/loadtest'

block ten
run 'python3 users.py http://127.0.0.1:8000/shows/990 10 0.5 2 10'
quiet 'sleep 3'
block think-zero
run 'python3 users.py http://127.0.0.1:8000/shows/990 100 0 5 30'
quiet 'sleep 5'
block open
run 'python3 hammer.py http://127.0.0.1:8000/shows/990 150:5'
quiet 'sleep 10'
block sale
run 'python3 users.py http://127.0.0.1:8000/shows/990 240 4 10 20'
stop
