#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `adaptive` shows
# app/routes/deals.js whole; `viewport`, `breakpoints`, `overflow`, `adaptive`
# and `what-to-check` show viewport.mjs and the three test files whole, and
# ../../lab.sh builds the project from those very blocks. What is STAGED rather
# than typed, beyond what ../../lab.sh's header lists for every lesson:
#   - "overflow-fail" and "deals-describe" run the FIRST version of a file a
#     later block in the same section replaces, taken out of the section with
#     ../../lab.sh fence and put back after;
#   - in "overflow-fixed", the two declarations that make .basket overflow are
#     deleted from app/public/style.css with sed for one run and put back;
#   - Playwright colours its report; the colour codes are taken out of every
#     transcript with sed, and nothing else is.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 7 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
plain() { sed 's/\x1b\[[0-9;]*m//g'; }
# A file as an earlier block of SECTION shows it, for one capture.
earlier() {
  cp "$P/$2" "/tmp/l7-keep"
  fence "$HERE/$1.md" "$2" > "$P/$2"
  chown ana:ana "$P/$2"
}
restore() { cp /tmp/l7-keep "$P/$1"; chown ana:ana "$P/$1"; }

block descriptor
run "node -p \"require('@playwright/test').devices['iPhone 13']\""
block landscape
run "node -p \"require('@playwright/test').devices['iPhone 13 landscape'].viewport\""

start_app
block viewport-root
run 'node viewport.mjs'
block viewport-deals
run 'node viewport.mjs /deals'

block curl-deals
run 'curl -si http://localhost:3000/deals'; echo
block curl-deals-phone
run "curl -s -A \"\$(node -p \"require('@playwright/test').devices['iPhone 13'].userAgent\")\" http://localhost:3000/deals"; echo
stop_app

block breakpoints
earlier breakpoints tests/responsive.spec.js
run 'npx playwright test tests/responsive.spec.js' | plain
restore tests/responsive.spec.js

block overflow-fail
earlier overflow tests/responsive.spec.js
run 'npx playwright test tests/responsive.spec.js' | plain
restore tests/responsive.spec.js

block overflow-known
run 'npx playwright test tests/responsive.spec.js' | plain

block overflow-fixed
cp app/public/style.css /tmp/l7-style.css
sed -i 's/ white-space: nowrap; min-width: 24rem;//' app/public/style.css
run 'npx playwright test tests/responsive.spec.js' | plain
cp /tmp/l7-style.css app/public/style.css; chown ana:ana app/public/style.css

block deals-describe
earlier adaptive tests/deals.spec.js
run 'npx playwright test tests/deals.spec.js' | plain
restore tests/deals.spec.js

block deals
run 'npx playwright test tests/deals.spec.js' | plain

block targets
run 'npx playwright test tests/targets.spec.js' | plain

block tablets
run "node -p \"Object.entries(require('@playwright/test').devices).filter(([name, d]) => d.isMobile && !/Mobile/.test(d.userAgent)).map(([name]) => name)\""
