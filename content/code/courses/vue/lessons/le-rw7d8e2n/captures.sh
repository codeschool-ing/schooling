#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l21.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l21.txt; done
#
# Starts from ~/vue as lesson 20 left it, on Node 22.23.4. vitest 5.0.5,
# @vue/test-utils 2.5.1 and jsdom 30.1.3 come from the npm registry. The
# configuration and the five test files are taken whole out of the sections
# that show them. Nothing here needs a clock: the tests set their own.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
node22() {
  bash "$LAB_SH" script 'node --version' | grep -q v22.23.4 && return
  quiet '~' 'curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz &&
    rm -rf ~/.local/node && mkdir ~/.local/node &&
    tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1 && rm node-v22.23.4-linux-x64.tar.xz'
}
tests() {
  shown pure-functions.md src/planner.test.ts $P/src/planner.test.ts
  shown mounting.md src/components/SessionRow.test.ts $P/src/components/SessionRow.test.ts
  shown interacting.md src/components/SessionForm.test.ts $P/src/components/SessionForm.test.ts
  shown with-the-store.md src/stores/planner.test.ts $P/src/stores/planner.test.ts
  shown async.md src/views/HomeView.test.ts $P/src/views/HomeView.test.ts
}
files() {
  node22
  quiet $P 'grep -q vitest package.json || npm install --silent --save-dev --save-exact vitest@5.0.5 @vue/test-utils@2.5.1 jsdom@30.1.3'
  shown installing.md vite.config.js $P/vite.config.js
  quiet $P "npm pkg set scripts.test='vitest'"
  tests
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-wff37aza
node22
block install
session $P 'npm install --save-dev --save-exact vitest@5.0.5 @vue/test-utils@2.5.1 jsdom@30.1.3'
shown installing.md vite.config.js $P/vite.config.js
block script
session $P "npm pkg set scripts.test='vitest'"
block none
session $P 'npx vitest run'
shown pure-functions.md src/planner.test.ts $P/src/planner.test.ts
block pure
session $P 'npx vitest run src/planner.test.ts'
block break
session $P "sed -i 's/(date.getDay() + 6) % 7/date.getDay() - 1/' src/planner.ts" 'npx vitest run src/planner.test.ts'
block unbreak
session $P "sed -i 's/date.getDay() - 1/(date.getDay() + 6) % 7/' src/planner.ts"
shown mounting.md src/components/SessionRow.test.ts $P/src/components/SessionRow.test.ts
block row
session $P 'npx vitest run src/components/SessionRow.test.ts'
shown interacting.md src/components/SessionForm.test.ts $P/src/components/SessionForm.test.ts
block form
session $P 'npx vitest run src/components/SessionForm.test.ts'
shown with-the-store.md src/stores/planner.test.ts $P/src/stores/planner.test.ts
block store
session $P 'npx vitest run src/stores/planner.test.ts'
shown async.md src/views/HomeView.test.ts $P/src/views/HomeView.test.ts
block week
session $P 'npx vitest run src/views/HomeView.test.ts'
block all
session $P 'npm test -- --run'
block types
session $P 'npm run type-check'
snapshot
