#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSONS. `the-stale-offer` shows
# app/routes/offer.js, app/public/offer.html and stale.mjs whole,
# `fresh-contexts` shows visitors.mjs, and tests/cache.spec.js is shown whole
# twice, the later version replacing the earlier; ../../lab.sh builds the
# project from those very blocks. What is STAGED rather than typed, beyond
# what ../../lab.sh's header lists for every lesson:
#   - in "cache-v1", tests/cache.spec.js is the first version, taken from
#     fresh-contexts.md; in "cache-v2", that version with the test the section
#     tells the student to add written at its end. "cache-final" puts the
#     staged final version back;
#   - in "static-304", the ETag is the one the server sent in "static-200",
#     read from its answer rather than typed;
#   - in "flaw-fixed", `max-age=600` in app/routes/offer.js replaced by
#     `no-cache` with sed for one run and put back: the fix the section
#     imagines somebody making;
#   - colour codes removed from Playwright's failure reports, which a
#     terminal draws in colour.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 4 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
nocolour() { sed 's/\x1b\[[0-9;]*m//g'; }
# The Nth fenced block of a section, labelled or not.
nth_fence() {
  python3 - "$1" "$2" <<'PY'
import re, sys
lines, n, k, found = open(sys.argv[1]).read().split("\n"), int(sys.argv[2]), 0, 0
while k < len(lines):
    m = re.match(r"^(`{3,})(\S*)\s*$", lines[k])
    if m:
        j = k + 1
        while lines[j].rstrip() != m.group(1):
            j += 1
        found += 1
        if found == n:
            print("\n".join(lines[k + 1:j]))
            sys.exit(0)
        k = j
    k += 1
sys.exit(f"nth_fence: {sys.argv[1]} has no block {n}")
PY
}

start_app
block static-200
run 'curl -s -D - -o /dev/null http://localhost:3000/style.css'
ETAG=$(curl -s -D - -o /dev/null http://localhost:3000/style.css | tr -d '\r' | awk -F': ' 'tolower($1)=="etag"{print $2}')
block static-304
run "curl -s -D - -o /dev/null -H 'If-None-Match: $ETAG' http://localhost:3000/style.css"
block offer-headers
run 'curl -s -i http://localhost:3000/api/offer'; echo
stop_app

block stale
bg_ana "cd $P && QUITANDA_LOG=1 exec npm start" /tmp/l4-log.out
wait_app
run 'node stale.mjs'
stop_bg
block stale-log
printf 'ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start\n'
grep -v "^Terminated$" /tmp/l4-log.out

bash "$HERE/../../lab.sh" fence "$HERE/fresh-contexts.md" tests/cache.spec.js > tests/cache.spec.js
chown ana:ana tests/cache.spec.js
block cache-v1
run 'npx playwright test tests/cache.spec.js' | nocolour
{ echo; nth_fence "$HERE/fresh-contexts.md" 3; } >> tests/cache.spec.js
block cache-v2
run 'npx playwright test tests/cache.spec.js' | nocolour

block visitors
start_app
run 'node visitors.mjs'
stop_app
rm -rf profile

bash "$HERE/../../lab.sh" fence "$HERE/testing-the-cache.md" tests/cache.spec.js > tests/cache.spec.js
chown ana:ana tests/cache.spec.js
block cache-final
bg_ana "cd $P && QUITANDA_LOG=1 exec npm start" /tmp/l4-log.out
wait_app
run 'npx playwright test tests/cache.spec.js' | nocolour
stop_bg
block cache-log
printf 'ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start\n'
grep -v "^Terminated$" /tmp/l4-log.out

block flaw-fixed
cp app/routes/offer.js /tmp/l4-offer.js
sed -i "s/'max-age=600'/'no-cache'/" app/routes/offer.js
run 'npx playwright test tests/cache.spec.js' | nocolour
cp /tmp/l4-offer.js app/routes/offer.js; chown ana:ana app/routes/offer.js

