#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `puppeteer` shows the new
# package.json, puppeteer/basket.mjs and how to install them, and
# `puppeteer-to-playwright` shows tests/banana.spec.js; ../../lab.sh builds the
# project from those very blocks. What is STAGED rather than typed, beyond
# what ../../lab.sh's header lists for every lesson:
#   - Puppeteer's browser. `npm install` runs with PUPPETEER_SKIP_DOWNLOAD=1,
#     because this machine cannot reach the Chrome download that Puppeteer
#     25.13.0 makes (Chrome 155.0.8059.39). Every Puppeteer run sets
#     PUPPETEER_EXECUTABLE_PATH to Playwright's Chromium 141 instead, which is
#     why the transcript prints `browser: Chrome/141...`. The prompt shows the
#     command the student types, without the variable.
#   - the shop. In "basket" and "no-wait" it is started in the background, as
#     the student starts it with `npm start` in another terminal.
#   - in "no-wait", the three lines of the waitForFunction call deleted with
#     sed, as the section asks, and the file put back after.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0, Puppeteer 25.13.0 and Chromium 141.0.7390.37,
# TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 11 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
CHROME=$ANA_HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome

block npm-install
rm -rf node_modules package-lock.json
run_npm install

block basket
start_app
printf 'ana@laptop:~/quitanda$ node puppeteer/basket.mjs\n'
as_ana "cd $P && PUPPETEER_EXECUTABLE_PATH=$CHROME node puppeteer/basket.mjs" 2>&1

block no-wait
cp puppeteer/basket.mjs /tmp/l11-basket.mjs
sed -i '/await page.waitForFunction(/,/^);$/d' puppeteer/basket.mjs
printf 'ana@laptop:~/quitanda$ for i in 1 2 3 4 5; do node puppeteer/basket.mjs | grep basket; done\n'
as_ana "cd $P && export PUPPETEER_EXECUTABLE_PATH=$CHROME && for i in 1 2 3 4 5; do node puppeteer/basket.mjs | grep basket; done" 2>&1
cp /tmp/l11-basket.mjs puppeteer/basket.mjs; chown ana:ana puppeteer/basket.mjs
stop_app

block banana
run 'npx playwright test tests/banana.spec.js'
