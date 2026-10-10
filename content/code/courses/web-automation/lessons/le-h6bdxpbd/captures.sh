#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. `the-shop` and `the-page`
# show every file of the project whole, and ../../lab.sh builds the project
# from those very blocks, so the two cannot differ. What is STAGED rather than
# typed, beyond what ../../lab.sh's header lists for every lesson:
#   - in "eaddrinuse", a first server started in the background and stopped
#     after;
#   - in "no-browser", ~/.cache/ms-playwright moved aside for one command and
#     put back;
#   - in "bad-json", a trailing comma written into package.json with sed and
#     taken out again; in "no-module", the "type" line deleted and put back;
#   - in "missing-script", app/public/app.js renamed to App.js for one run, the
#     mistake the section describes; in "page-error", one address in app.js
#     changed with sed and restored.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 1 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1

block versions
run_in "$ANA_HOME" 'node --version'
run_in "$ANA_HOME" 'npm --version'

block npm-install
rm -rf node_modules package-lock.json
run_npm install

block start
printf 'ana@laptop:~/quitanda$ npm start\n'
bg_ana "cd $P && exec npm start" /tmp/l1-start.out
wait_app; cat /tmp/l1-start.out
block curl-basket
curl -s -o /dev/null -X POST -H 'Content-Type: application/json' -d '{"id":"banana"}' localhost:3000/api/basket
run 'curl -s http://localhost:3000/api/basket'; echo
block curl-reset
run 'curl -s -X POST http://localhost:3000/api/reset'; echo
block eaddrinuse
run 'npm start'
stop_bg

block smoke
run 'npx playwright test'

block no-browser
mv "$ANA_HOME/.cache/ms-playwright" "$ANA_HOME/.cache/ms-playwright.aside"
run 'npx playwright test'
mv "$ANA_HOME/.cache/ms-playwright.aside" "$ANA_HOME/.cache/ms-playwright"

block wrong-folder
run_in "$ANA_HOME" 'npm start'

block bad-json
cp package.json /tmp/l1-package.json
sed -i 's/"test": "playwright test"/"test": "playwright test",/' package.json
run 'npm start'
cp /tmp/l1-package.json package.json; chown ana:ana package.json

block no-module
sed -i '/"type": "module",/d' package.json
printf 'ana@laptop:~/quitanda$ npm start\n'
bg_ana "cd $P && exec npm start" /tmp/l1-start.out
wait_app; sleep 0.5; stop_bg
grep -v "^Terminated$" /tmp/l1-start.out
cp /tmp/l1-package.json package.json; chown ana:ana package.json

block source-html
start_app
run "curl -s http://localhost:3000/ | grep -n products"

block look
run 'node look.mjs'
stop_app

block server-log
printf 'ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start\n'
bg_ana "cd $P && QUITANDA_LOG=1 exec npm start" /tmp/l1-log.out
wait_app
as_ana "cd $P && node look.mjs" >/dev/null 2>&1
stop_bg
grep -v "^Terminated$" /tmp/l1-log.out

block missing-script
mv app/public/app.js app/public/App.js
start_app
run 'node look.mjs'
stop_app
mv app/public/App.js app/public/app.js

block page-error
sed -i "s|getJson('/api/products')|getJson('/api/product')|" app/public/app.js
start_app
run 'node look.mjs'
stop_app
sed -i "s|getJson('/api/product')|getJson('/api/products')|" app/public/app.js
