#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the box office of lesson 1, the pages of
# lessons 12 and 13 (logo.svg, book.html, book2.html), lesson 12's contrast.py
# and lesson 13's audit.js,
# and this lesson's tab.js and book3.html, copied out of the lessons by `shown`
# rather than pasted into nano; lesson 13's `npm init -y` and `npm install` in
# ~/a11y, run quietly, which is why this machine keeps the network; a fresh
# database from seed.py, because tab.js books seats 20 and 21 of show 981,
# and seed.py again before the second run, as the lesson tells the student to. The
# server runs in the background, where the lesson has the student run it in a
# terminal of its own. Booking ids differ if the database is not fresh.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L12="$HERE_DIR/../le-jhzcs1zb"
L13="$HERE_DIR/../le-75mv4n2t"

machine l14 net
shown "$L1/the-boxoffice.md" "$L12/booking-page.md" "$L12/contrast.md" \
      "$L13/axe-in-playwright.md" "$L13/fix-and-rerun.md" \
      "$HERE_DIR/tab-order.md" "$HERE_DIR/fixing.md" 2>/dev/null
at '~/a11y'
quiet 'npm init -y && npm install playwright@1.56.0 @axe-core/playwright@4.13.0'
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

at '~/a11y'
block focus-colour
run 'python3 contrast.py 1a5fb4 ffffff'
block tab2
run 'node tab.js http://localhost:8000/book2.html'
at '~/boxoffice/static'
block diff
run 'diff book2.html book3.html'
at '~/boxoffice'
quiet 'python3 seed.py'
at '~/a11y'
block tab3
run 'node tab.js http://localhost:8000/book3.html'
block audit3
run 'node audit.js http://localhost:8000/book3.html'
stop
