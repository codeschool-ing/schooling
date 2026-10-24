#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l8.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l8.txt; done
#
# It runs on the library as lesson 7 left it, the commit tagged v0.2.0, and on
# the planner at lesson-7, which this lesson does not change: it tags the same
# commit lesson-8. A run before this one may have published 0.3.0 to the
# registry; that version is unpublished first, quietly, so the publish below
# is the first one. Nothing else is staged beyond what lab.sh lists.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-7 && git clean -fdq'
quiet '~/planner-ui' 'git switch -q main; git tag -d v0.3.0; git reset -q --hard v0.2.0 && git clean -fdq && npm ci'
bg reg '~/registry' 'npx -y verdaccio@6.10.7 --config ./config.yaml'
wait_port 4873
quiet '~/planner-ui' 'npm unpublish @planner/ui@0.3.0 --force'

# The element and its page.
shown a-custom-element.md src/session-element.ts '~/planner-ui/src/session-element.ts'
shown a-custom-element.md index.html '~/planner-ui/index.html'
bg dev '~/planner-ui' 'npx vite'
wait_port 5173
sleep 2
block vite
bg_show dev
bg_stop dev

# Tests.
block pw
session '~/planner-ui' 'npm install --save-dev --save-exact @playwright/test@1.63.0 @axe-core/playwright@4.14.0 2>&1 | tail -1'
shown testing-the-element.md playwright.config.ts '~/planner-ui/playwright.config.ts'
shown testing-the-element.md tests/session-element.spec.ts '~/planner-ui/tests/session-element.spec.ts'
block ignore
session '~/planner-ui' "printf 'test-results\nplaywright-report\n' >> .gitignore"
block test
session '~/planner-ui' 'npx playwright test 2>&1 | tail -1'
block commit
session '~/planner-ui' 'git add -A && git commit -qm "Add <planner-session>, its demo page and its tests"'
block leak
session '~/planner-ui' "sed -i 's/#root = this.attachShadow({ mode: \"open\" });/#root = this;/' src/session-element.ts" \
  "npx playwright test 2>&1 | grep -E '^  [0-9]+ (failed|passed)|Received: |\"color-contrast\"'" \
  'git restore src/session-element.ts'

# The release.
block export
session '~/planner-ui' "echo 'export { PlannerSession, definePlannerSession } from \"./session-element\";' >> src/index.ts" \
  'npx tsc && echo types ok'
shown in-any-framework.md CHANGELOG.md '~/planner-ui/CHANGELOG.md'
block release
session '~/planner-ui' 'git add -A && git commit -qm "Export <planner-session>"' 'npm version minor' \
  'git log --oneline --decorate -3' 'npm run build > /dev/null && npm publish 2>&1 | tail -1'
quiet '~/planner' 'git tag -f lesson-8'
bg_stop reg INT
