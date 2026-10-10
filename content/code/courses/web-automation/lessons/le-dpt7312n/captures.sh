#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `browsers.config.js`,
# `tests/contexts.spec.js` and `tests/waiting.spec.js` are shown whole in this
# lesson, and ../../lab.sh builds the project from those very blocks. What is
# STAGED rather than typed, beyond what ../../lab.sh's header lists for every
# lesson:
#   - Firefox and WebKit are not installed, because Playwright's downloads are
#     blocked here; "firefox" is the real failure of a project whose browser is
#     missing, and nothing in the lesson shows either browser passing;
#   - in "waiting-fail", the two failing tests the section shows are appended
#     to tests/waiting.spec.js for one run and the file is put back after;
#   - Playwright colours its output when it thinks a terminal is reading it,
#     and some of it reaches a pipe coloured anyway; the escape codes are
#     stripped from everything below, which is what a terminal does with them
#     on screen. No character of text is changed.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 10 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
exec > >(sed -u 's/\x1b\[[0-9;]*[A-Za-z]//g')

block protocol-methods
run "DEBUG=pw:protocol npx playwright test tests/smoke.spec.js 2>&1 | grep SEND | grep -o '\"method\":\"[A-Za-z.]*\"' | head -8"
block protocol-count
run "DEBUG=pw:protocol npx playwright test tests/smoke.spec.js 2>&1 | grep -o 'SEND\|RECV' | sort | uniq -c"
block pipe
run "DEBUG=pw:browser npx playwright test tests/smoke.spec.js 2>&1 | grep -o 'remote-debugging-[a-z]*'"

block list
run 'npx playwright test --config browsers.config.js --list tests/smoke.spec.js'
block project-greedy
run 'npx playwright test --config browsers.config.js --project chromium tests/smoke.spec.js'
block chromium
run 'npx playwright test --config browsers.config.js --project=chromium tests/smoke.spec.js tests/contexts.spec.js'
block firefox
run 'npx playwright test --config browsers.config.js --project=firefox tests/smoke.spec.js'

block contexts
run 'npx playwright test tests/contexts.spec.js'

block waiting
run 'npx playwright test tests/waiting.spec.js'
block waiting-fail
cp tests/waiting.spec.js /tmp/l10-waiting.spec.js
sed -n '/^```javascript$/,/^```$/p' "$HERE/auto-waiting.md" | awk 'BEGIN{n=0} /^```javascript$/{n++; next} /^```$/{next} n==2' > /tmp/l10-failing.js
{ echo; cat /tmp/l10-failing.js; } >> tests/waiting.spec.js
chown ana:ana tests/waiting.spec.js
run 'npx playwright test tests/waiting.spec.js'
cp /tmp/l10-waiting.spec.js tests/waiting.spec.js; chown ana:ana tests/waiting.spec.js

block trace-run
run 'npx playwright test tests/contexts.spec.js --trace on'
block trace-ls
run 'ls test-results'
block trace-unzip
run "unzip -l test-results/contexts-two-shoppers-*/trace.zip"

block report-run
run 'npx playwright test tests/smoke.spec.js --reporter=list,html'
block report-ls
run 'ls playwright-report'
