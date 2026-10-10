#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `the-search-page` shows the
# three files of the search page whole, `what-async-means` and `the-race` show
# at-load.mjs and race.mjs, and the three versions of tests/search.spec.js are
# in `a-naive-test`, `waiting-for-the-right-thing` and `the-defect`, the last
# one being what `stage 3` leaves. What is STAGED rather than typed, beyond
# what ../../lab.sh's header lists for every lesson:
#   - in "v1" and "v2", the earlier versions of tests/search.spec.js, taken
#     from their own sections with `lab.sh fence` and replaced by the final one
#     after;
#   - in "v3-fixed", app/public/search.js with its listener replaced by the
#     one printed in "fixed-listener" (the fix the section describes), and the
#     original put back after;
#   - Playwright's colour codes are stripped from the test runs, which is what
#     a terminal shows once it has drawn them.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 3 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolor() { sed 's/\x1b\[[0-9;]*m//g'; }
version() {   # write one section's version of the test file into the project
  bash "$HERE/../../lab.sh" fence "$HERE/$1" tests/search.spec.js > tests/search.spec.js
  chown ana:ana tests/search.spec.js
}

start_app
block at-load
run 'node at-load.mjs'
run 'node at-load.mjs 500'
block race-0
run 'node race.mjs'
block race-200
run 'node race.mjs papaya 200'
stop_app

block v1
version a-naive-test.md
run 'npx playwright test tests/search.spec.js' | nocolor
block v2
version waiting-for-the-right-thing.md
run 'npx playwright test tests/search.spec.js' | nocolor
block v3
version the-defect.md
run 'npx playwright test tests/search.spec.js' | nocolor

block fixed-listener
cat > /tmp/l3-listener.js <<'JS'
input.addEventListener('input', async () => {
  const asked = input.value;
  waiting += 1;
  results.setAttribute('aria-busy', 'true');
  const response = await fetch('/api/search?q=' + encodeURIComponent(asked));
  const found = await response.json();
  waiting -= 1;
  if (waiting === 0) results.setAttribute('aria-busy', 'false');
  // The fix: an answer to a question the box no longer asks is dropped.
  if (asked !== input.value) return;
  results.replaceChildren(...found.map((p) => {
    const li = document.createElement('li');
    li.textContent = p.name;
    return li;
  }));
  count.textContent = `${found.length} found`;
});
JS
cat /tmp/l3-listener.js
cp app/public/search.js /tmp/l3-search.js
python3 - app/public/search.js /tmp/l3-listener.js <<'PY'
import sys
s = open(sys.argv[1]).read()
i = s.index("// One request per key")
open(sys.argv[1], "w").write(s[:i] + open(sys.argv[2]).read())
PY
block v3-fixed
run 'npx playwright test tests/search.spec.js' | nocolor
cp /tmp/l3-search.js app/public/search.js; chown ana:ana app/public/search.js
