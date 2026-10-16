#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `what-headless-is` shows
# modes.mjs, `two-headless-chromes` shows headless.config.js and
# selenium/headless.mjs, and `differences-that-bite` shows both versions of
# tests/headless.spec.js, the second being what `stage 17` leaves. What is
# STAGED rather than typed, beyond what ../../lab.sh's header lists for every
# lesson:
#   - Xvfb. The student installs it with `sudo apt-get install xvfb`; the
#     machine these were recorded on already had Ubuntu's package, so the
#     install is not shown, and "xvfb-version" prints what was there;
#   - in "bite-*", the first version of tests/headless.spec.js, taken from its
#     own section with `lab.sh fence` and replaced by the final one after;
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them;
#   - three commands are cut with `head`, `grep` or `tail`, and the command
#     printed says so: a launch line hundreds of characters long, an error
#     with a stack, and the timing runs, where only the summary is compared.
#
# Recorded 2026-10-11 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0, Chromium 141.0.7390.37, selenium-webdriver 4.51.0 and
# chromedriver 141.0.7390.122, TZ=America/Sao_Paulo. Firefox could not be
# installed here and nothing in this lesson ran it.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 17 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
version() {   # write one section's version of the test file into the project
  bash "$HERE/../../lab.sh" fence "$HERE/$1" tests/headless.spec.js > tests/headless.spec.js
  chown ana:ana tests/headless.spec.js
}
cp tests/headless.spec.js /tmp/l17-final.js   # the version stage 17 leaves
SUITE='tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js'

start_app
block modes-shell
run 'node modes.mjs shell'
block no-display
run 'node modes.mjs headed 2>&1 | head -12'
block modes-new
run 'node modes.mjs new'
block launching
run 'DEBUG=pw:browser node modes.mjs shell 2>&1 | grep -o "<launching> [^ ]*"'
run 'DEBUG=pw:browser node modes.mjs new 2>&1 | grep -o "<launching> [^ ]*"'
block du
run 'du -sh ~/.cache/ms-playwright/*'
block install-help
run 'npx playwright install --help | head -12'
block chrome-old
run 'google-chrome --headless=old --dump-dom http://localhost:3000/deals'
block selenium-new
run 'node selenium/headless.mjs --headless=new'
run 'node selenium/headless.mjs --headless'
block selenium-old
run 'node selenium/headless.mjs --headless=old 2>&1 | grep Error:'
block firefox-options
run "node -e \"import('selenium-webdriver/firefox.js').then(({ default: firefox }) => console.log(new firefox.Options().addArguments('-headless').get('moz:firefoxOptions')))\""
block xvfb-version
run 'dpkg -s xvfb | grep ^Version'
block modes-headed
run 'xvfb-run node modes.mjs headed'
block modes-big
run 'xvfb-run -s "-screen 0 1920x1080x24" node modes.mjs headed'
block selenium-headed
run 'xvfb-run node selenium/headless.mjs'
block pineapple-box
run "node -e \"import('@playwright/test').then(async ({ chromium }) => { const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 780, height: 493 } }); await p.goto('http://localhost:3000/'); console.log(await p.getByTestId('product-pineapple').boundingBox()); await b.close(); })\""
stop_app

block headed-no-display
run 'npx playwright test --headed tests/smoke.spec.js 2>&1 | head -14' | nocolor
block headed-xvfb
run 'xvfb-run npx playwright test --headed tests/smoke.spec.js' | nocolor

block bite-shell
version differences-that-bite.md
run 'npx playwright test tests/headless.spec.js' | nocolor
block bite-new
run 'npx playwright test --config headless.config.js --project=new-headless tests/headless.spec.js' | nocolor
block bite-headed
run 'xvfb-run npx playwright test --headed tests/headless.spec.js' | nocolor
cp /tmp/l17-final.js tests/headless.spec.js; chown ana:ana tests/headless.spec.js
block fixed-both
run 'npx playwright test --config headless.config.js tests/headless.spec.js' | nocolor
block fixed-headed
run 'xvfb-run npx playwright test --headed tests/headless.spec.js' | nocolor

block speed-one
run "npx playwright test --workers 1 $SUITE" | nocolor
block speed
for i in 1 2 3; do
  run "npx playwright test --workers 1 $SUITE | tail -1" | nocolor
  run "npx playwright test --config headless.config.js --project=new-headless --workers 1 $SUITE | tail -1" | nocolor
  run "xvfb-run npx playwright test --headed --workers 1 $SUITE | tail -1" | nocolor
done
