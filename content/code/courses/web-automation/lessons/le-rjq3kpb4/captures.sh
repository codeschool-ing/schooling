#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of web-automation, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it; each block of output starts with a
# line `##### <name>` naming it.
#
#   sudo bash captures.sh       # root, because it acts as the user ana
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON. `one-page` shows the four
# files of the single-page app and `spa-look.mjs` whole, and every test file is
# shown whole behind its label; ../../lab.sh builds the project from those
# very blocks, so the two cannot differ. What is STAGED rather than typed,
# beyond what ../../lab.sh's header lists for every lesson:
#   - in "naive" and "fixed", tests/spa.spec.js is the first and the second
#     version `one-page` shows, written over the project's final one for one
#     run each and put back;
#   - in "fallback", the route `deep-links` shows unlabelled is written to
#     app/routes/spa-fallback.js for one run and deleted, as the prose says;
#   - in "no-ready", the line with `navigator.serviceWorker.ready` deleted from
#     tests/offline.spec.js with sed and the file restored;
#   - in "stale", the heading in app/public/spa/spa.js changed with sed, the
#     edit the section asks the student to make by hand, and restored after;
#   - .spa-profile is deleted before "spa-look-1", so that run is a first
#     visit, and kept until "stale";
#   - Playwright colours its error messages; the escape codes are stripped
#     from the transcripts, which shows the text a terminal draws.
#
# Recorded 2026-10-10 on Ubuntu 24.04 with Node 22.22.0, npm 10.9.4,
# Playwright 1.56.0 and Chromium 141.0.7390.37, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
source "$HERE/../../lab.sh" lib
lock
machine
stage 5 || exit 1
P=$REPO_DEFAULT
cd "$P" || exit 1
plain() { sed 's/\x1b\[[0-9;]*m//g'; }

# The Nth block of a section labelled `as PATH:`, 1-based; or, with a
# pattern instead of a path, the first block whose body contains it.
nth() {
  python3 - "$1" "$2" "$3" <<'PY'
import re, sys
lines, want, n = open(sys.argv[1]).read().split("\n"), sys.argv[2], int(sys.argv[3])
i, prev, ended, seen = 0, "", False, 0
while i < len(lines):
    m = re.match(r"^(`{3,})(\S*)\s*$", lines[i])
    if not m:
        if not lines[i].strip(): ended = True
        else:
            prev = lines[i].strip() if ended else prev + " " + lines[i].strip(); ended = False
        i += 1; continue
    j = i + 1
    while lines[j].rstrip() != m.group(1): j += 1
    body = "\n".join(lines[i + 1:j])
    label = re.search(r"\bas `([\w./-]+)`:$", prev.rstrip())
    if (label and label.group(1) == want) or (not label and want in body and n == 0):
        seen += 1
        if seen == max(n, 1): print(body); sys.exit(0)
    prev, i = "", j + 1
sys.exit(f"nth: no block {want} {n} in {sys.argv[1]}")
PY
}
put() { nth "$HERE/$1" "$2" "$3" > "$4" && chown ana:ana "$4"; }

cp tests/spa.spec.js /tmp/l5-spa.spec.js
rm -rf .spa-profile

block spa-look-1
start_app
run 'node spa-look.mjs'
stop_app

block naive
put one-page.md tests/spa.spec.js 1 tests/spa.spec.js
run 'npx playwright test tests/spa.spec.js' | plain

block fixed
put one-page.md tests/spa.spec.js 2 tests/spa.spec.js
run 'npx playwright test tests/spa.spec.js' | plain
cp /tmp/l5-spa.spec.js tests/spa.spec.js; chown ana:ana tests/spa.spec.js

block look-basket
start_app
run 'node look.mjs http://localhost:3000/spa/basket'
stop_app

block deep-link
run 'npx playwright test tests/spa.spec.js' | plain

block fallback
put deep-links.md 'Not part of quitanda' 0 app/routes/spa-fallback.js
run 'npx playwright test tests/spa.spec.js' | plain
rm -f app/routes/spa-fallback.js

block spa-look-2
start_app
run 'node spa-look.mjs'
stop_app

block offline
run 'npx playwright test tests/offline.spec.js' | plain

block no-ready
cp tests/offline.spec.js /tmp/l5-offline.spec.js
sed -i '/navigator.serviceWorker.ready/d' tests/offline.spec.js
run 'npx playwright test tests/offline.spec.js' | plain
cp /tmp/l5-offline.spec.js tests/offline.spec.js; chown ana:ana tests/offline.spec.js

block stale-curl
cp app/public/spa/spa.js /tmp/l5-spa.js
sed -i "s|'<h1>Fruit</h1><ul></ul>'|'<h1>Fresh fruit</h1><ul></ul>'|" app/public/spa/spa.js
start_app
run "curl -s http://localhost:3000/spa/spa.js | grep -n 'Fresh fruit'"
stop_app

block stale
printf 'ana@laptop:~/quitanda$ QUITANDA_LOG=1 npm start\n'
bg_ana "cd $P && QUITANDA_LOG=1 exec npm start" /tmp/l5-log.out
wait_app
run 'node spa-look.mjs'
stop_bg
block stale-log
grep -v "^Terminated$" /tmp/l5-log.out
cp /tmp/l5-spa.js app/public/spa/spa.js; chown ana:ana app/public/spa/spa.js
