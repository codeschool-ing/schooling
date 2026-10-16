#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `the-fixed-name` shows
# app/routes/users.js and app/public/signup.html whole; the four versions of
# tests/signup.spec.js are in `the-fixed-name`, `unique-data`,
# `setup-through-the-api` and `cleanup`, the last being what `stage 15`
# leaves; tests/names.spec.js and tests/setup-cost.spec.js are in
# `unique-data` and `setup-through-the-api`; the three versions of
# tests/basket-data.spec.js are in `cleanup` (two) and `shared-state` (the
# last, which `stage 15` leaves). What is STAGED rather than typed, beyond
# what ../../lab.sh's header lists for every lesson:
#   - the earlier versions of the two test files, taken from their sections
#     (the first labelled block with `lab.sh fence`, a second one in the same
#     section with `nth` below) and replaced by the final ones after;
#   - "a server already running" is the shop started in the background, as
#     the student's `npm start` in a second terminal; `QUITANDA_LOG=1` is set
#     on it for "signup-v4";
#   - tests/interrupted.spec.js, which the section prints (from the heredoc
#     below, block "interrupted-file") and tells the student to delete after
#     the experiment; it is written here and deleted after;
#   - the interruption: `timeout -s INT 3` delivers the signal Ctrl+C sends to
#     the whole command, and `timeout -s KILL 3` the one a cancelled job or a
#     dead machine amounts to; the prose shows both commands as typed;
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them.
#
# Recorded 2026-10-11 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 15 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
version() {   # SECTION PATH: the first block SECTION labels PATH, into the project
  bash "$HERE/../../lab.sh" fence "$HERE/$1" "$2" > "$2"; chown ana:ana "$2"
}
nth() {       # SECTION PATH N: the Nth block SECTION labels PATH, into the project
  python3 - "$HERE/$1" "$2" "$3" > "$2" <<'PY'
import re, sys
text, want, n = open(sys.argv[1]).read(), sys.argv[2], int(sys.argv[3])
blocks = re.findall(r"as `([\w./-]+)`:\n\n```\w*\n(.*?)\n```", text, re.S)
print([b for p, b in blocks if p == want][n - 1])
PY
  chown ana:ana "$2"
}
user() { run "curl -s -w ' %{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{\"name\":\"$1\"}' http://localhost:3000/api/users"; }

# ---- the-fixed-name
start_app
block curl-users
user maria
user maria
run "curl -s -w '%{http_code}\n' -X DELETE 'http://localhost:3000/api/users?name=maria'"
user maria
stop_app

version the-fixed-name.md tests/signup.spec.js
block fixed-fresh
run 'npx playwright test tests/signup.spec.js' | nocolor
run 'npx playwright test tests/signup.spec.js' | nocolor
block fixed-reused
start_app
run 'npx playwright test tests/signup.spec.js' | nocolor
run 'npx playwright test tests/signup.spec.js' | nocolor
stop_app

# ---- unique-data
block names
run 'npx playwright test tests/names.spec.js --repeat-each 2 --workers 2' | nocolor
run 'npx playwright test tests/names.spec.js --repeat-each 2 --workers 2' | nocolor
version unique-data.md tests/signup.spec.js
block unique-twice
start_app
run 'npx playwright test tests/signup.spec.js' | nocolor
run 'npx playwright test tests/signup.spec.js' | nocolor
stop_app

# ---- setup-through-the-api
block setup-cost
run 'npx playwright test tests/setup-cost.spec.js' | nocolor
version setup-through-the-api.md tests/signup.spec.js
block signup-v3
run 'npx playwright test tests/signup.spec.js' | nocolor

# ---- cleanup
block interrupted-file
cat > tests/interrupted.spec.js <<'JS'
import { test, expect } from '@playwright/test';

test.afterEach(async ({ request }) => {
  await request.delete('/api/users', { params: { name: 'joao' } });
  console.log('afterEach: joao deleted');
});

test('a slow test that creates joao', async ({ page, request }) => {
  const created = await request.post('/api/users', { data: { name: 'joao' } });
  expect(created.status()).toBe(201);
  console.log('joao created');
  await page.goto('/signup.html');
  await page.waitForTimeout(10000);   // stands for ten seconds of real work
});
JS
chown ana:ana tests/interrupted.spec.js
cat tests/interrupted.spec.js
start_app
block interrupted-int
run 'timeout -s INT 3 npx playwright test tests/interrupted.spec.js' | nocolor
user joao
run "curl -s -X DELETE 'http://localhost:3000/api/users?name=joao'"
block interrupted-kill
run 'timeout -s KILL 3 npx playwright test tests/interrupted.spec.js' | nocolor
user joao
stop_app
rm -f tests/interrupted.spec.js

version cleanup.md tests/signup.spec.js
block signup-v4
printf 'ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start\n'
bg_ana "cd $P && QUITANDA_LOG=1 exec npm start" /tmp/l15-log.out
wait_app
run 'npx playwright test tests/signup.spec.js' | nocolor
stop_bg
block signup-v4-log
grep -v "^Terminated$" /tmp/l15-log.out

version cleanup.md tests/basket-data.spec.js
block basket-v1
run 'npx playwright test tests/basket-data.spec.js' | nocolor
nth cleanup.md tests/basket-data.spec.js 2
block basket-v2
run 'npx playwright test tests/basket-data.spec.js' | nocolor

# ---- shared-state
block basket-parallel
run 'npx playwright test tests/basket-data.spec.js --fully-parallel --workers 2' | nocolor
version shared-state.md tests/basket-data.spec.js
block basket-serial
run 'npx playwright test tests/basket-data.spec.js --fully-parallel --workers 2' | nocolor
block basket-banana
run 'npx playwright test tests/basket-data.spec.js tests/banana.spec.js --workers 2' | nocolor
block basket-one
run 'npx playwright test tests/basket-data.spec.js tests/banana.spec.js --workers 1' | nocolor

# ---- the final state of this lesson's files
block final
run 'npx playwright test tests/signup.spec.js tests/basket-data.spec.js tests/names.spec.js tests/setup-cost.spec.js --workers 1' | nocolor
