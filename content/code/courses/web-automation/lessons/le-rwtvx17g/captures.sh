#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of web-automation, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `playwright-codegen` shows
# pick.mjs, and `the-recording-runs` shows recorded.config.js,
# recorded/side.spec.js, recorded/codegen.spec.js and tests/two-fruit.spec.js;
# ../../lab.sh builds the project from those very blocks. The page object and
# tests/fixtures.js are lesson 12's. NOTHING HERE WAS RECORDED BY A RECORDER:
# Selenium IDE, BugBug, Ghost Inspector and `playwright codegen` all need a
# screen, and this machine has none. The .side file and the two recorded test
# files are written by hand in the shape those tools save, and the lesson says
# so. What is STAGED rather than typed, beyond what ../../lab.sh's header lists
# for every lesson:
#   - the shop. In "pick" and "basket-after" it is started in the background,
#     as the student starts it with `npm start` in another terminal, so that
#     the basket can be read after the run; every other run lets Playwright's
#     webServer start it.
#   - in "change", the button's words in app/public/app.js changed with sed,
#     the edit the section asks for; in "fix", the same words changed with sed
#     in pages/product-card.js. Both files are put back after "project", as
#     the section tells the student to.
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 20 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
LINES="grep -E '✓|✘|^  [0-9]+ (failed|flaky|passed)'"

block help
run 'npx playwright codegen --help'

block pick
start_app
run 'PWDEBUG=console node pick.mjs'
run 'PWDEBUG=console node pick.mjs'
stop_app

block side
run 'npx playwright test --config recorded.config.js recorded/side.spec.js' | nocolor

block codegen
run 'npx playwright test --config recorded.config.js recorded/codegen.spec.js' | nocolor

block codegen-again
run "for i in 1 2 3 4 5; do npx playwright test --config recorded.config.js recorded/codegen.spec.js -g 'banana|two fruit' | grep -E '✓|✘|Received string'; done" | nocolor

block basket-after
start_app
run "npx playwright test --config recorded.config.js recorded/codegen.spec.js -g 'banana|two fruit' | grep -E '✓|✘'" | nocolor
run 'curl -s http://localhost:3000/api/basket'; echo
stop_app

block hand
run 'npx playwright test tests/two-fruit.spec.js --repeat-each 3 --workers 1' | nocolor

cp app/public/app.js /tmp/l20-app.js
cp pages/product-card.js /tmp/l20-card.js
sed -i 's|<button type="button">Add to basket</button>|<button type="button">Add to cart</button>|' app/public/app.js
block change
run 'grep -n "Add to" app/public/app.js'

block count
run 'grep -c "Add to basket" recorded/codegen.spec.js pages/product-card.js tests/page-object.spec.js tests/two-fruit.spec.js'

block after
run "npx playwright test --config recorded.config.js recorded/codegen.spec.js | $LINES" | nocolor
run "npx playwright test tests/page-object.spec.js tests/two-fruit.spec.js --workers 1 | $LINES" | nocolor

sed -i "s|{ name: 'Add to basket' }|{ name: 'Add to cart' }|" pages/product-card.js
block fix
run 'grep -n "Add to" pages/product-card.js'
run "npx playwright test tests/page-object.spec.js tests/two-fruit.spec.js --workers 1 | $LINES" | nocolor

block project
run "grep -rc 'Add to basket' --include='*.js' --include='*.mjs' --exclude-dir=node_modules . | grep -v ':0\$'"

cp /tmp/l20-app.js app/public/app.js
cp /tmp/l20-card.js pages/product-card.js
chown ana:ana app/public/app.js pages/product-card.js
