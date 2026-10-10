#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. Lesson 1 builds the shop and
# this lesson adds count.mjs (in "the-tree") and tests/locators.spec.js, shown
# three times: a first version in "what-breaks", a second and a final one in
# "stable-locators". ../../lab.sh builds the project from those very blocks,
# so the two cannot differ. What is STAGED rather than typed, beyond what
# ../../lab.sh's header lists for every lesson:
#   - the shop is started in the background for the count.mjs runs, where the
#     lesson has the student start it with `npm start` in another terminal;
#   - in "breaks" and "strict", the earlier versions of tests/locators.spec.js
#     are put back for one run with `lab.sh fence`, and the final one after;
#   - the Playwright runs have FORCE_COLOR=0 in their environment, which the
#     printed command does not show: the test runner colours its error
#     messages, and a page cannot. Nothing else in the output changes.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 2 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1

# A Playwright run as ana, printed as she typed it, without colour codes.
run_plain() {
  printf 'ana@laptop:~/quitanda$ %s\n' "$*"
  as_ana "cd '$P' && FORCE_COLOR=0 $*" 2>&1
}
# Put back the version of a file that SECTION.md labels, for one run.
version_of() {
  bash "$HERE/../../lab.sh" fence "$HERE/$1" "$2" > "$P/$2"
  chown ana:ana "$P/$2"
}

start_app

block count-banana
run "node count.mjs '[data-testid=\"product-banana\"]'"

block count-css
run "node count.mjs 'li' '.card' 'button' 'button:visible' '.card button' '.card small' '.card > small'"

block count-attr
run "node count.mjs '[data-testid]' '[data-testid^=\"product-\"]' '[data-testid=\"product-mango\"] h2' '.card:nth-child(2) h2' 'li:nth-child(9)' '.card:has(small)' '[role=\"status\"]'"

block count-long
run "node count.mjs 'main > ul#products > li.card:nth-child(2) > h2' '[data-testid=\"product-mango\"] h2'"

block count-xpath
run "node count.mjs '//h2[text()=\"Mango\"]' '//li[h2=\"Mango\"]//button' '//h2[.=\"Mango\"]/following-sibling::button' '//button/ancestor::li[h2=\"Mango\"]'"

block count-xpath-brittle
run "node count.mjs '//p[text()=\"R\$ 5,90\"]' '//p[contains(., \"5,90\")]' '/html/body/main/ul/li[1]/button' 'xpath=(//li)[2]//h2'"

block count-id
run "node count.mjs '[data-testid=\"product-banana\"]' '#card-4821' '[id^=\"card-\"]'"

stop_app

block breaks
version_of what-breaks.md tests/locators.spec.js
run_plain 'npx playwright test tests/locators.spec.js'

block strict
version_of stable-locators.md tests/locators.spec.js
run_plain 'npx playwright test tests/locators.spec.js'

block stable
stage 2 || exit 1
cd "$P" || exit 1
run_plain 'npx playwright test tests/locators.spec.js'
