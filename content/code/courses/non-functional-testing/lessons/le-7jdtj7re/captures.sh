#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the box office of lesson 1, the pages of
# lessons 12 to 14 (logo.svg, book.html, book2.html, book3.html) and lesson
# 13's audit.js, and this lesson's tree.js, book4.html and charter.js, copied
# out of the lessons by `shown` rather than pasted into nano; lesson 13's
# `npm init -y` and `npm install` in ~/a11y, run quietly, which is why this
# machine keeps the network; a fresh database from seed.py. The server runs in
# the background, where the lesson has the student run it in a terminal of its
# own.
#
# NO SCREEN READER RAN. The lab has no desktop, so nothing here is speech: the
# transcripts are the accessibility tree, which is what a screen reader is
# given, and the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L12="$HERE_DIR/../le-jhzcs1zb"
L13="$HERE_DIR/../le-75mv4n2t"
L14="$HERE_DIR/../le-hxrmsg2h"

machine l15 net
shown "$L1/the-boxoffice.md" "$L12/booking-page.md" "$L12/contrast.md" \
      "$L13/axe-in-playwright.md" "$L13/fix-and-rerun.md" "$L14/tab-order.md" "$L14/fixing.md" \
      "$HERE_DIR/accessibility-tree.md" "$HERE_DIR/announcing-errors.md" "$HERE_DIR/test-charter.md" \
      2>/dev/null
at '~/a11y'
quiet 'npm init -y && npm install playwright@1.56.0 @axe-core/playwright@4.13.0'
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

at '~/a11y'
block tree1
run 'node tree.js http://localhost:8000/book.html'
block tree3
run 'node tree.js http://localhost:8000/book3.html'
at '~/boxoffice/static'
block diff
run 'diff book3.html book4.html'
at '~/a11y'
block tree4
run 'node tree.js http://localhost:8000/book4.html'
block audit4
run 'node audit.js http://localhost:8000/book4.html'
block charter
run 'node charter.js'
run 'cat charter.md'
stop
