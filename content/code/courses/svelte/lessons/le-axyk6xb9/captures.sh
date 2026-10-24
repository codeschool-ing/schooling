#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l19.txt
#   F="python3 ../../lab/fill.py"
#   $F vitest.md /tmp/l19.txt --blocks install,script,first
#   $F failing.md /tmp/l19.txt --blocks check-pass,break,fail,mend
#   $F runes-in-tests.md /tmp/l19.txt --blocks runes
#   $F components.md /tmp/l19.txt --blocks render
#   $F playwright.md /tmp/l19.txt --blocks pw-install,ignore,e2e-script,e2e
#   $F what-to-test.md /tmp/l19.txt --blocks test-script,all
#
# It starts from the project as lesson 18 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py. Playwright finds the
# browser lesson 1 installed for look, at the same version, so nothing is
# downloaded here.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 18

bg_stop dev; bg_stop web
show() { shown "$1" "$2" "~/planner/${2%#*}"; }

block install
session '~/planner' 'npm install --save-dev vitest@5.0.5'
show vitest.md vite.config.js
block script
session '~/planner' "npm pkg set scripts.test:unit='vitest run'"
show vitest.md src/lib/week.test.ts
block first
session '~/planner' 'npm run test:unit'

show failing.md src/lib/server/check.test.ts
block check-pass
session '~/planner' 'npm run test:unit'
block break
session '~/planner' "sed -i 's/date < addDays(monday, 7)/date <= addDays(monday, 7)/' src/lib/week.ts"
block fail
session '~/planner' 'npm run test:unit 2>&1 | grep -B2 -A12 FAIL'
block mend
session '~/planner' "sed -i 's/date <= addDays(monday, 7)/date < addDays(monday, 7)/' src/lib/week.ts"

show runes-in-tests.md src/lib/planner.svelte.test.ts
block runes
session '~/planner' 'npm run test:unit 2>&1 | tail -6'

show components.md src/lib/WeekTotal.test.ts
block render
session '~/planner' 'npm run test:unit 2>&1 | tail -6'

block pw-install
session '~/planner' 'npm install --save-dev @playwright/test@1.63.0'
show playwright.md src/lib/server/planner.ts
block ignore
session '~/planner' "printf '/test-results\n/playwright-report\n' >> .gitignore"
show playwright.md playwright.config.ts
show playwright.md e2e/planner.test.ts
block e2e-script
session '~/planner' "npm pkg set scripts.test:e2e='playwright test'"
block e2e
session '~/planner' 'npm run test:e2e'

block test-script
session '~/planner' "npm pkg set scripts.test='npm run check && npm run test:unit && npm run test:e2e'"
block all
session '~/planner' "npm test 2>&1 | grep -E 'svelte-check found|Tests|passed|failed'"

quiet '~/planner' 'git checkout data/planner.json; rm -f data/planner.json.new'
done_lesson 19 "unit tests with Vitest, end-to-end tests with Playwright"
