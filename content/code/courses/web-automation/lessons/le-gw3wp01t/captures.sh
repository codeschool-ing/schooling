#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `what-arrives` and
# `hydration` show app/routes/ssr.js and app/public/ssr.js whole, and the
# sections show every test file whole; ../../lab.sh builds the project from
# those very blocks. What is STAGED rather than typed, beyond what
# ../../lab.sh's header lists for every lesson:
#   - in "click-at-once" and "click-repeat", tests/ssr.spec.js is the FIRST
#     version `hydration` shows, printed back out of that section with
#     ../../lab.sh's `fence`, because `waiting-for-ready` replaces it at the
#     same path; the final version is put back after "disabled";
#   - in "disabled", the two edits `waiting-for-ready` shows are made with sed
#     and undone after the run, as the section tells the student to do;
#   - Playwright colours a failure even through a pipe; its escape codes are
#     stripped from the output with sed, which leaves the text a terminal
#     shows with the colours removed.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 6 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolour() { sed 's/\x1b\[[0-9;]*m//g'; }

start_app
block curl-csr
run "curl -s http://localhost:3000/ | grep -c '<h2>'"
block curl-ssr
run "curl -s http://localhost:3000/ssr | grep '<h2>'"
block look-csr
run 'node look.mjs'
block look-ssr
run 'node look.mjs http://localhost:3000/ssr'
stop_app

cp tests/ssr.spec.js /tmp/l6-ssr.spec.js
fence "$HERE/hydration.md" tests/ssr.spec.js > tests/ssr.spec.js
chown ana:ana tests/ssr.spec.js

block click-at-once
run 'npx playwright test tests/ssr.spec.js' | nocolour
block click-repeat
run "npx playwright test tests/ssr.spec.js --repeat-each 5 --workers 1 | grep -E 'passed|failed|✘|✓'" | nocolour

block disabled
cp app/routes/ssr.js /tmp/l6-route.js; cp app/public/ssr.js /tmp/l6-public.js
sed -i 's/data-id="${p.id}">Add to basket/data-id="${p.id}" disabled>Add to basket/' app/routes/ssr.js
sed -i 's/^for (const button of document.querySelectorAll(.button\[data-id\].)) {$/&\n  button.disabled = false;/' app/public/ssr.js
run 'npx playwright test tests/ssr.spec.js' | nocolour
cp /tmp/l6-route.js app/routes/ssr.js; cp /tmp/l6-public.js app/public/ssr.js
cp /tmp/l6-ssr.spec.js tests/ssr.spec.js
chown ana:ana app/routes/ssr.js app/public/ssr.js tests/ssr.spec.js

block ready
run 'npx playwright test tests/ssr.spec.js --repeat-each 5 --workers 1' | nocolour

block no-script
run 'npx playwright test tests/no-script.spec.js' | nocolour

block ssr-html
run 'npx playwright test tests/ssr-html.spec.js' | nocolour

block all
run 'npx playwright test tests/ssr.spec.js tests/no-script.spec.js tests/ssr-html.spec.js' | nocolour
