#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `implicit-waits` shows
# selenium/implicit.mjs, `explicit-waits` selenium/ssr.test.js,
# `custom-conditions` selenium/conditions.test.js and tests/conditions.spec.js,
# `the-fixed-sleep` and `too-late` two versions each of tests/sleeps.spec.js and
# tests/toast.spec.js, the last of each being what `stage 13` leaves. What is
# STAGED rather than typed, beyond what ../../lab.sh's header lists for every
# lesson:
#   - in "sleeps-v1" and "toast-v1", the first versions of those test files,
#     taken from their sections with `lab.sh fence`, and the final ones put
#     back after; in "sleeps-v2", the one-number change the section asks for
#     (the /ssr test's first sleep from 1000 to 2000), made with python;
#   - in "scratch" and "slow", tests/scratch.spec.js written from the first and
#     the second unlabelled javascript block of `timeouts`, and deleted after;
#   - "selenium-defaults" and "playwright-defaults" are grep over the installed
#     packages in node_modules;
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them.
#
# Recorded 2026-10-16 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0, Chromium 141.0.7390.37, selenium-webdriver 4.51.0 and
# chromedriver 141.0.7390.122, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 13 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
version() {   # write one section's first block for PATH into the project
  bash "$HERE/../../lab.sh" fence "$HERE/$1" "$2" > "$2"
  chown ana:ana "$2"
}
unlabelled() {   # the Nth javascript block of a section, for a scratch file
  python3 - "$HERE/$1" "$2" <<'PY'
import re, sys
blocks = re.findall(r"^```javascript\n(.*?)\n```$", open(sys.argv[1]).read(), re.S | re.M)
scratch = [b for b in blocks if "test.beforeEach(async ({ page })" in b or "test.setTimeout(1000)" in b]
print(scratch[int(sys.argv[2])])
PY
}
cp tests/sleeps.spec.js /tmp/l13-sleeps.js
cp tests/toast.spec.js /tmp/l13-toast.js

block selenium-defaults
run "grep -n 'wait(condition, timeout = 0' node_modules/selenium-webdriver/lib/webdriver.js"

start_app
block implicit
run 'node selenium/implicit.mjs'
block explicit
run 'node --test --test-reporter=tap selenium/ssr.test.js'
block selenium-both
run 'node --test --test-concurrency=1 --test-reporter=tap selenium/ssr.test.js selenium/conditions.test.js'
stop_app

block sleeps-v1
version the-fixed-sleep.md tests/sleeps.spec.js
run 'npx playwright test tests/sleeps.spec.js --workers 1' | nocolor
block sleeps-v2
python3 - tests/sleeps.spec.js <<'PY'
import sys
s = open(sys.argv[1]).read()
old = "await page.goto('/ssr');\n  await page.waitForTimeout(1000);"
assert s.count(old) == 1
open(sys.argv[1], "w").write(s.replace(old, old.replace("1000", "2000")))
PY
run 'npx playwright test tests/sleeps.spec.js --workers 1' | nocolor
block sleeps-v3
cp /tmp/l13-sleeps.js tests/sleeps.spec.js; chown ana:ana tests/sleeps.spec.js
run 'npx playwright test tests/sleeps.spec.js --workers 1' | nocolor

block conditions
run 'npx playwright test tests/conditions.spec.js --workers 1' | nocolor

block playwright-defaults
run "grep -n -e 'defaultTimeout = ' -e 'defaultExpectTimeout = ' -e 'actionTimeout: \[' -e 'navigationTimeout: \[' -e 'launchTimeout = ' node_modules/playwright/lib/common/config.js node_modules/playwright/lib/matchers/expect.js node_modules/playwright/lib/index.js node_modules/playwright/lib/plugins/webServerPlugin.js"
run "grep -n -o -e 'globalTimeout, 0)' -e 'toPass?.timeout, 0)' node_modules/playwright/lib/common/config.js node_modules/playwright/lib/matchers/matchers.js"

block scratch
unlabelled timeouts.md 0 > tests/scratch.spec.js; chown ana:ana tests/scratch.spec.js
run 'npx playwright test tests/scratch.spec.js --workers 1' | nocolor
block slow
unlabelled timeouts.md 1 > tests/scratch.spec.js; chown ana:ana tests/scratch.spec.js
run 'npx playwright test tests/scratch.spec.js --workers 1' | nocolor
rm -f tests/scratch.spec.js

block toast-v1
version too-late.md tests/toast.spec.js
run 'npx playwright test tests/toast.spec.js' | nocolor
block toast-v2
cp /tmp/l13-toast.js tests/toast.spec.js; chown ana:ana tests/toast.spec.js
run 'npx playwright test tests/toast.spec.js' | nocolor
