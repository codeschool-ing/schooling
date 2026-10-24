#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 10 > out.txt
#
# It starts from the tag lesson-9 and leaves lesson-10. server/axe.mjs and
# the test are taken from the lesson's own listings by lab/extract.py; the
# two fixes are exact replacements, shown by `git diff`.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The dev server runs in the background, started by serve(), as from
#     another terminal.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 9

block install
run $P 'npm install --save-exact -D @axe-core/playwright@4.14.0'
put axe.md server/axe.mjs $P/server/axe.mjs
serve 5173 $P 'npm run dev'
block report
run $P "node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'"
put first-run.md e2e/a11y.spec.ts $P/e2e/a11y.spec.ts
block red
run $P 'npx playwright test e2e/a11y.spec.ts --reporter=list 2>&1 | grep -E "^  (✓|✘)|^    [-+] |passed|failed"'

fix src/view.ts '      icon.src = "/book.svg";' '      icon.src = "/book.svg";
      icon.alt = "";'
fix src/style.css '.session.done { color: #aaa; }' '.session.done { color: #6b6b6b; }'
block diff
run $P 'git diff src'
block green
run $P 'npx playwright test e2e/a11y.spec.ts --reporter=list'
block report-after
run $P "node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'"
unserve 5173
block commit
export GIT_AUTHOR_DATE='2026-10-23 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "axe at WCAG 2.2 AA: decorative icons, and a done grey that reads"'
leave 10
