#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `three-layers` shows the
# three test files whole, and ../../lab.sh builds the project from those very
# blocks and from every earlier lesson's. What is STAGED rather than typed,
# beyond what ../../lab.sh's header lists for every lesson:
#   - in "no-browser", PLAYWRIGHT_BROWSERS_PATH pointed at an empty folder for
#     one command, so Playwright finds no browser;
#   - in "defect-format", the `/ 100` in app/public/app.js's showBasket taken
#     out with sed for one run and put back; in "defect-qty", `* line.qty`
#     taken out of app/store.js's total() the same way; in "relabel", the
#     button's text changed from "Add to basket" to "Add to cart" and back.
#     The sections say each change is made for one run.
# Playwright forces colour on in its workers, so an `expect` failure carries
# ANSI colour codes; they are stripped from this script's output (exactly
# ESC[...m), as lessons 2, 3, 5 and 7 do. The two Playwright files run with
# --workers 1 whenever they run together, because both write the one shared
# basket (lessons 15 and 19).
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 21 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1

{
block unit-run
run 'node --test --test-reporter=tap unit/total.test.js'

block api-run
run 'npx playwright test tests/basket-api.spec.js'

block ui-run
run 'npx playwright test tests/basket-ui.spec.js'

block no-browser
as_ana "mkdir -p $ANA_HOME/no-browsers"
run 'PLAYWRIGHT_BROWSERS_PATH=~/no-browsers npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1'
as_ana "rmdir $ANA_HOME/no-browsers"

block time-once
run 'time node --test --test-reporter=tap unit/total.test.js > /dev/null'
run 'time npx playwright test tests/basket-api.spec.js > /dev/null'
run 'time npx playwright test tests/basket-ui.spec.js > /dev/null'

block time-twenty
run 'time for i in $(seq 20); do node --test --test-reporter=tap unit/total.test.js > /dev/null; done'
run 'time npx playwright test tests/basket-api.spec.js --repeat-each 20 --workers 1 --reporter=dot'
run 'time npx playwright test tests/basket-ui.spec.js --repeat-each 20 --workers 1 --reporter=dot'

block defect-format
cp app/public/app.js /tmp/l21-app.js
sed -i 's|money.format(basket.total / 100)|money.format(basket.total)|' app/public/app.js
run 'node --test --test-reporter=tap unit/total.test.js'
run 'npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1'
cp /tmp/l21-app.js app/public/app.js; chown ana:ana app/public/app.js

block defect-qty
cp app/store.js /tmp/l21-store.js
sed -i 's|return sum + product.price \* line.qty;|return sum + product.price;|' app/store.js
run 'node --test --test-reporter=tap unit/total.test.js'
run 'npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1'
cp /tmp/l21-store.js app/store.js; chown ana:ana app/store.js

block relabel
sed -i 's|<button type="button">Add to basket</button>|<button type="button">Add to cart</button>|' app/public/app.js
run 'npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1'
cp /tmp/l21-app.js app/public/app.js; chown ana:ana app/public/app.js

block final
run 'node --test --test-reporter=tap unit/total.test.js'
run 'npx playwright test tests/basket-api.spec.js tests/basket-ui.spec.js --workers 1'
} 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
