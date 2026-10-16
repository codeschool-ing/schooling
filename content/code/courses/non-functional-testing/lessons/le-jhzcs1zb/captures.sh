#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the box office of lesson 1 and the files of
# this lesson (logo.svg, book.html, contrast.py), copied out of the lessons by
# `shown` rather than pasted into nano; a fresh database from seed.py. The
# server runs in the background, where the lesson has the student run it in a
# terminal of its own. Dates in the headers differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"

machine l12
shown "$L1/the-boxoffice.md" "$HERE_DIR/booking-page.md" "$HERE_DIR/contrast.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

block serve
run 'curl -s -D - -o /dev/null localhost:8000/book.html'
run 'curl -s -D - -o /dev/null localhost:8000/logo.svg'

at '~/a11y'
block contrast
run 'python3 contrast.py 999999 ffffff'
run 'python3 contrast.py 767676 ffffff'
run 'python3 contrast.py 777777 ffffff'
run 'python3 contrast.py ffffff 7a1f2b'
run 'python3 contrast.py dd0000 ffffff'
run 'python3 contrast.py 222222 ffffff'
stop
