#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l6.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l6.txt; done
#
# It runs on the planner as lesson 5 left it, the commit tagged lesson-5, and
# tags what it leaves lesson-6. STAGED: Chromium. Playwright 1.63.0 is pointed
# at the recording computer's own copy of the build it downloads, through
# PLAYWRIGHT_BROWSERS_PATH (see lab.sh); `npx playwright install chromium`,
# which the lesson tells the student to run, was not run here. The Storybook
# development server's banner is drawn in colour and is described rather than
# quoted.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-5 && git clean -fdq -e node_modules && npm ci'

shown components-as-functions.md src/components.ts '~/planner/src/components.ts'
shown components-as-functions.md src/view.ts '~/planner/src/view.ts'
block checks
session '~/planner' 'npx tsc && npm test 2>&1 | grep Tests'

block install
session '~/planner' 'npm install --save-dev --save-exact storybook@10.6.3 @storybook/html-vite@10.6.3 @storybook/addon-docs@10.6.3 @storybook/addon-a11y@10.6.3 2>&1 | tail -3'
shown installing-storybook.md .storybook/main.ts '~/planner/.storybook/main.ts'
shown installing-storybook.md .storybook/preview.ts '~/planner/.storybook/preview.ts'
block scripts
session '~/planner' 'npm pkg set scripts.storybook="storybook dev -p 6006" scripts.build-storybook="storybook build"'
block ignore
session '~/planner' "printf 'storybook-static\ntest-results\nplaywright-report\n' >> .gitignore"

shown a-first-story.md src/session-row.stories.ts '~/planner/src/session-row.stories.ts'
shown every-state.md src/week-summary.stories.ts '~/planner/src/week-summary.stories.ts'
block index
session '~/planner' "npx storybook build > /dev/null 2>&1 && node -e \"for (const id in require('./storybook-static/index.json').entries) console.log(id)\""

shown both-themes.md .storybook/preview.ts '~/planner/.storybook/preview.ts'

block static
session '~/planner' 'npm run build-storybook > /dev/null 2>&1 && ls storybook-static'
bg sb '~/planner' 'node host.mjs storybook-static 6007'
wait_port 6007
block static-start
bg_show sb
block static-curl
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' 'http://127.0.0.1:6007/iframe.html?id=planner-session-row--done&viewMode=story'"
bg_stop sb INT

block pw
session '~/planner' 'npm install --save-dev --save-exact @playwright/test@1.63.0 @axe-core/playwright@4.14.0 2>&1 | tail -1' \
  'npm pkg set scripts.test="vitest run src"' 'npx playwright --version'
shown stories-as-tests.md playwright.config.ts '~/planner/playwright.config.ts'
shown stories-as-tests.md tests/stories.spec.ts '~/planner/tests/stories.spec.ts'
block first-run
session '~/planner' 'npm run build-storybook > /dev/null 2>&1' 'npx playwright test > first-run.txt 2>&1' \
  "grep -m1 \"doesn't exist\" first-run.txt" "grep -E '^  [0-9]+ (failed|passed)' first-run.txt" \
  'ls tests/stories.spec.ts-snapshots | head -4' 'npx playwright test 2>&1 | tail -1' 'rm first-run.txt'
block radius
session '~/planner' "sed -i 's/border-radius: var(--space-1);/border-radius: var(--space-4);/' src/style.css" \
  'npm run build-storybook > /dev/null 2>&1' \
  "npx playwright test -g 'to-do in light' 2>&1 | grep -E 'pixels \\(ratio|1 failed' | head -2" \
  'ls test-results/*/'
block radius-back
session '~/planner' 'git checkout src/style.css'

block grey
session '~/planner' "sed -i 's/{color.grey-600}/{color.grey-400}/' tokens.json" 'npm run tokens > /dev/null' \
  'npm run build-storybook > /dev/null 2>&1' "npx playwright test -g 'done in light' 2>&1 | sed -n '/Error:/,/^    + \\]/p'"
block grey-back
session '~/planner' 'git checkout tokens.json src/tokens.css' 'npm run build-storybook > /dev/null 2>&1' \
  'npx playwright test 2>&1 | tail -2'
block commit
session '~/planner' 'git add .storybook src playwright.config.ts tests package.json package-lock.json .gitignore' \
  'git commit -qm "A component library, documented in Storybook and tested story by story"'
quiet '~/planner' 'npm run build'
quiet '~/planner' 'git tag -f lesson-6'
