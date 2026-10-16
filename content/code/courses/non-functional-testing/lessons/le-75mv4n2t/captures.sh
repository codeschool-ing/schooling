#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of non-functional-testing, as a
# script that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the box office of lesson 1, the booking
# page and logo of lesson 12, and this lesson's rules.js, audit.js and
# book2.html, copied out of the lessons by `shown` rather than pasted into
# nano; `npm init -y`, run quietly because what it prints is the package.json
# it wrote; a fresh database from seed.py. The machine keeps the network for
# the npm install. The server runs in the background, where the lesson has the
# student run it in a terminal of its own. Lighthouse runs with the Chromium
# lesson 10 installed, and the CHROME_PATH line lesson 10 adds to
# ~/.profile is added here too. Timings differ on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
source "$(dirname "$0")/../../capture.sh"
HERE_DIR=$(cd "$(dirname "$0")" && pwd)
L1="$HERE_DIR/../le-ymhwee3h"
L12="$HERE_DIR/../le-jhzcs1zb"

machine l13 net
shown "$L1/the-boxoffice.md" "$L12/booking-page.md" "$L12/contrast.md" \
      "$HERE_DIR/axe-in-playwright.md" "$HERE_DIR/fix-and-rerun.md" 2>/dev/null
at '~/boxoffice'
quiet 'python3 seed.py'
serve 'python3 app.py'

at '~/a11y'
quiet 'npm init -y'
quiet "echo 'export CHROME_PATH=\$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome' >> ~/.profile"
block install
run 'npm install playwright@1.56.0 @axe-core/playwright@4.13.0'
block rules
run 'node rules.js'
block audit
run 'node audit.js; echo "exit $?"'

at '~/boxoffice/static'
block diff
run 'diff book.html book2.html'
at '~/a11y'
block audit2
run 'node audit.js http://localhost:8000/book2.html'
block gate
run 'for page in book.html book2.html; do node audit.js http://localhost:8000/$page > /dev/null && echo "$page passes" || echo "$page fails"; done'

block lighthouse
run 'lighthouse http://localhost:8000/book.html --only-categories=accessibility --output=json --output-path=book.json --chrome-flags="--headless=new --no-sandbox" --quiet'
run 'jq -r ".categories.accessibility.score" book.json'
run 'jq -r ".audits[] | select(.score == 0) | .id + \": \" + .title" book.json'
block lighthouse2
run 'lighthouse http://localhost:8000/book2.html --only-categories=accessibility --output=json --output-path=book2.json --chrome-flags="--headless=new --no-sandbox" --quiet'
run 'jq -r ".categories.accessibility.score" book2.json'
run 'jq -r ".audits[] | select(.score == 0) | .id + \": \" + .title" book2.json'
block manual
run 'jq -r ".audits[] | select(.scoreDisplayMode == \"manual\") | .title" book2.json'
stop
