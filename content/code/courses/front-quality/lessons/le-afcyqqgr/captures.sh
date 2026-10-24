#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 4 > out.txt
#
# It starts from the tag lesson-3 and leaves lesson-4. Every file is taken
# from the lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "dry-run" runs with PLAYWRIGHT_BROWSERS_PATH unset, so Playwright names
#     the folder a student's machine would use. Every other block uses the
#     build already at /opt/pw-browsers; `npx playwright install` was not run
#     (the lesson says so), because the recording machine could not reach
#     Playwright's download server.
#   - "fail" changes 160 to 150 in the first test with an exact replacement,
#     and "restored" puts it back with `git checkout`, which is shown.
#   - Cypress is not installed or run anywhere: its binary download is
#     refused by the recording machine's network, and cypress.md says so.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 3

block install
run $P 'npm install --save-exact -D @playwright/test@1.63.0'
block dry-run
run $P 'env -u PLAYWRIGHT_BROWSERS_PATH npx playwright install --dry-run chromium'

put config.md playwright.config.ts $P/playwright.config.ts
block ignore
run $P 'printf "test-results\nplaywright-report\n" >> .gitignore'
run $P 'cat .gitignore'

put first-e2e.md e2e/planner.spec.ts $P/e2e/planner.spec.ts
block collide
run $P 'npm test 2>&1 | head -n 20'
put config.md vite.config.ts $P/vite.config.ts
block separate
run $P 'npm test'

block first
run $P 'npx playwright test --reporter=list'
block commit-e2e
export GIT_AUTHOR_DATE='2026-10-20 11:00:00 -0300' GIT_COMMITTER_DATE='2026-10-20 11:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "End-to-end tests with Playwright"'

put waiting.md e2e/waiting.spec.ts $P/e2e/waiting.spec.ts
block flaky
run $P 'npx playwright test e2e/waiting.spec.ts --reporter=list'
block rm-waiting
run $P 'rm e2e/waiting.spec.ts'

put network.md e2e/empty.spec.ts $P/e2e/empty.spec.ts
block empty
run $P 'npx playwright test e2e/empty.spec.ts --reporter=list'

fix e2e/planner.spec.ts 'This week: 160 min' 'This week: 150 min'
block fail
run $P 'npx playwright test e2e/planner.spec.ts -g "shows the week" --reporter=list'
block context
run $P 'ls test-results/planner-the-home-page-shows-the-week-chromium'
run $P "sed -n '/^- heading/,/^- paragraph/p' test-results/planner-the-home-page-shows-the-week-chromium/error-context.md"
block restored
run $P 'git checkout e2e/planner.spec.ts'
run $P 'npx playwright test --reporter=list'

block both
run $P 'npm test'
run $P 'npx playwright test'
block check-script
run $P 'npm pkg set scripts.check="npm test && npx playwright test"'
run $P 'npm run check 2>&1 | tail -n 4'
block commit
export GIT_AUTHOR_DATE='2026-10-20 11:30:00 -0300' GIT_COMMITTER_DATE='2026-10-20 11:30:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "An empty course, and one command for both suites"'
run $P 'git log --oneline | head -n 3'
leave 4
