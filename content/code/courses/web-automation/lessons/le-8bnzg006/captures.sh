#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `stage 22` is the project
# as lessons 1 to 22 leave it; this lesson adds one file, slowest.mjs, shown
# whole in `the-suite-as-a-product`. It runs tests other lessons wrote:
# lesson 7's tests/responsive.spec.js and lesson 16's evidence/visual.spec.js
# with evidence.config.js. What is STAGED rather than typed, beyond what
# ../../lab.sh's header lists for every lesson:
#   - in "a-cost-model", four edits made with sed and undone after each run,
#     the four the section's table describes: a card border from #c9d6c3 to
#     #2f6f4e in app/public/style.css; the banana's price from 590 to 620 in
#     app/store.js; `color: #fff` added to `.price` in style.css; and the two
#     declarations lesson 7 blames, `white-space: nowrap; min-width: 24rem;`,
#     deleted from `.basket`. The screenshot baseline is deleted first, so the
#     first run writes it, as a student's first run does;
#   - the test runs are cut with grep to the lines the prose reads, and the
#     grep is printed as part of the command;
#   - Playwright's colour codes are stripped, which is what a terminal shows
#     once it has drawn them.
# Nothing here opens a window: the HTML report lesson 16's configuration
# writes was not opened.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 22 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }

VIS="npx playwright test --config evidence.config.js evidence/visual.spec.js | grep -E '✓|✘|^ +[0-9]+ pixels|snapshot doesn|^  [0-9]+ (passed|failed)'"
OVF="npx playwright test tests/responsive.spec.js -g sideways | grep -E '✓|✘|Expected to fail|^  [0-9]+ (passed|failed)'"
both() { run "$VIS" | nocolor; run "$OVF" | nocolor; }
keep() { cp "$1" "/tmp/l22-$(basename "$1")"; }
back() { cp "/tmp/l22-$(basename "$1")" "$1"; chown ana:ana "$1"; }

# --- a-cost-model
rm -rf evidence/visual.spec.js-snapshots test-results
block baseline
run "$VIS" | nocolor
block as-it-is
both

block border
keep app/public/style.css
sed -i 's/border: 1px solid #c9d6c3/border: 1px solid #2f6f4e/' app/public/style.css
both
back app/public/style.css

block price
keep app/store.js
sed -i "s/name: 'Banana', price: 590/name: 'Banana', price: 620/" app/store.js
both
back app/store.js

block hidden-price
keep app/public/style.css
sed -i 's/^\.price { margin: 0 0 0.75rem; }/.price { margin: 0 0 0.75rem; color: #fff; }/' app/public/style.css
both
run "npx playwright test tests/smoke.spec.js | grep -E '✓|✘|^  [0-9]+ (passed|failed)'" | nocolor
back app/public/style.css

block basket-fixed
keep app/public/style.css
sed -i 's/white-space: nowrap; min-width: 24rem; //' app/public/style.css
both
back app/public/style.css

# --- deleting-tests
block test-files
run 'ls tests'
run 'ls tests/*.spec.js | wc -l'
block known
run 'grep -rn "test.fail(" tests | wc -l'
run 'grep -rn "test.fail(" tests'

# --- the-suite-as-a-product
rm -rf test-results
block suite-w1
run 'npx playwright test --workers 1 --reporter=json > report.json; echo "exit code $?"'
run 'node slowest.mjs report.json'
block suite-5
run "for i in 1 2 3 4 5; do npx playwright test | grep -E '^  [0-9]+ (failed|flaky|passed)|^    tests/'; done" | nocolor
block suite-why
run "npx playwright test | grep -E 'using [0-9]+ workers|^  [0-9]+\) |Expected:|Received:'" | nocolor
