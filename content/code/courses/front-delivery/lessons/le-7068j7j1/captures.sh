#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l3.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l3.txt; done
#
# It runs on the planner as lesson 2 left it, the commit tagged lesson-2, and
# tags what it leaves lesson-3. STAGED: nothing beyond the files shown in the
# lesson; the timings in "caching" are this machine's on the day, and its
# network reaches the npm registry directly.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~/planner' 'git switch -q main; git branch -D green-heading; git worktree prune; git reset -q --hard lesson-2 && git clean -fdq && npm ci'
quiet '~' 'rm -rf ~/ci ~/previews ~/previews-src /tmp/empty-cache'

# npm ci.
block ci-refuses
session '~/planner' "sed -i 's/\"typescript\": \"6.0.3\"/\"typescript\": \"6.0.2\"/' package.json" 'npm ci'
block ci-ok
session '~/planner' 'git checkout package.json' 'npm ci'

# First tests.
block vitest
session '~/planner' 'npm install --save-dev --save-exact vitest@5.0.5' \
  'npm pkg set scripts.test="vitest run"' 'grep -A1 "\"vitest\"\|\"test\"" package.json'
shown first-tests.md src/planner.test.ts '~/planner/src/planner.test.ts'
block test
session '~/planner' 'npm test'
block test-fails
session '~/planner' "sed -i 's/s.date < end/s.date <= end/' src/planner.ts" 'npm test'
block test-commit
session '~/planner' 'git checkout src/planner.ts' 'git add package.json package-lock.json src/planner.test.ts' \
  'git commit -qm "Test the planner with Vitest"'

# A clean checkout.
shown a-clean-checkout.md src/format.ts '~/planner/src/format.ts'
block forgot
session '~/planner' "sed -i '2i import { duration } from \"./format\";' src/view.ts" \
  "sed -i 's/\${s.minutes} min /\${duration(s.minutes)} /' src/view.ts" \
  'npx tsc && npm test 2>&1 | tail -4' 'git status --short' 'git commit -qam "Show durations in hours and minutes"'
block clean
session '~' 'rm -rf ~/ci && git clone -q ~/planner ~/ci && cd ~/ci' 'npm ci 2>&1 | tail -1' 'npx tsc'
block clean-fixed
session '~/planner' 'git add src/format.ts' 'git commit -qm "Add the duration formatter"' \
  'cd ~/ci && git pull -q' 'npx tsc && npm test 2>&1 | tail -4' 'npx vite build 2>&1 | tail -1'
quiet '~' 'rm -rf ~/ci'

# The workflow.
shown the-workflow.md .github/workflows/ci.yml '~/planner/.github/workflows/ci.yml'
block workflow-commit
session '~/planner' 'git add .github/workflows/ci.yml' 'git commit -qm "Run the checks on every pull request"'

# Caching.
block cache
session '~/planner' 'rm -rf node_modules /tmp/empty-cache && time npm ci --cache /tmp/empty-cache > /dev/null' \
  'rm -rf node_modules && time npm ci --cache /tmp/empty-cache > /dev/null'
quiet '~' 'rm -rf /tmp/empty-cache'

# Previews by hand.
block branch
session '~/planner' 'git switch -q -c green-heading' "echo 'h1 { color: #2f6f4e; }' >> src/style.css" \
  'git commit -qam "A green heading"' 'git switch -q main'
block builds
session '~/planner' 'rm -rf ~/previews && mkdir ~/previews' \
  'git worktree add -q ~/previews-src/green-heading green-heading' \
  'npx vite build --base=/main/ --outDir ~/previews/main --emptyOutDir > /dev/null' \
  '(cd ~/previews-src/green-heading && npm ci > /dev/null && npx vite build --base=/green-heading/ --outDir ~/previews/green-heading --emptyOutDir > /dev/null)' \
  'ls ~/previews'
bg pv '~/planner' 'node host.mjs ~/previews 8080'
wait_port 8080
block pv-start
bg_show pv
block pv-curl
session '~/planner' "curl -s http://127.0.0.1:8080/main/ | grep -o 'assets/[^\"]*\.css'" \
  "curl -s http://127.0.0.1:8080/green-heading/ | grep -o 'assets/[^\"]*\.css'" \
  "css=\$(curl -s http://127.0.0.1:8080/green-heading/ | grep -o 'assets/[^\"]*\.css')" \
  "curl -s http://127.0.0.1:8080/green-heading/\$css | grep -o 'h1{[^}]*}'"
bg_stop pv INT
block pv-clean
session '~/planner' 'git worktree remove ~/previews-src/green-heading' 'rm -rf ~/previews ~/previews-src' 'git branch'
quiet '~/planner' 'npm run build'
quiet '~/planner' 'git tag -f lesson-3'
