#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l10.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l10.txt; done
#
# It runs on the planner as lesson 9 left it, the commit tagged lesson-9, and
# tags what it leaves lesson-10. The registry from lesson 7 is started because
# `npm ci` fetches @planner/ui from it. STAGED: in "Watching it fail", the
# person opening the JavaScript course, stopping the GraphQL server and
# pressing Mark done is a Playwright script (/tmp/fdlab/l10/rollback.cjs, run
# with the planner's own @playwright/test). It prints what the page showed
# just after the press and two seconds later, and the browser console's
# messages, into the block "observed", which no fence quotes: the lesson's
# prose about the row and the console is checked against it.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
bg reg '~/registry' 'npx -y verdaccio@6.10.7 --config ./config.yaml'
wait_port 4873
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-9 && git clean -fdq && npm ci'

# Apollo from the terminal.
block install
session '~/planner' 'npm install --save-exact @apollo/client@4.3.3 rxjs@7.8.2 2>&1 | tail -1'
shown apollo-from-the-terminal.md api/cache.mjs '~/planner/api/cache.mjs'
bg api '~/planner' 'node api/server.mjs'
wait_port 4000
block cache
session '~/planner' 'node api/cache.mjs'
sleep 0.5
block api-log
bg_show api
bg_stop api INT

# The planner on Apollo.
for f in src/queries.ts src/apollo.ts src/api.ts src/main.ts src/queries.test.ts; do
  shown the-planner-on-apollo.md $f "~/planner/$f"
done
block rm
session '~/planner' 'git rm -q src/graphql.ts' "npx tsc && npm test 2>&1 | grep -E 'Test Files|Tests'" \
  'git add -A && git commit -qm "Move the planner'"'"'s GraphQL to Apollo Client"'

# Taking an optimistic update back.
bg api2 '~/planner' 'node api/server.mjs'
wait_port 4000
bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
block observed
bash ../../lab.sh script "cd ~/planner; NODE_PATH=\$HOME/planner/node_modules node /tmp/fdlab/l10/rollback.cjs $STATE/api2.pid" 2>&1
sleep 0.5
block devlog
bg_show dev
bg_stop dev INT
bg_stop api2 INT

# What it costs.
block sizes
session '~/planner' "npm run build 2>&1 | grep 'assets/.*js'" "VITE_GRAPHQL_URL=/graphql npm run build 2>&1 | grep 'assets/.*js'"
block trap
session '~/planner' "sed -i '1a import \"./queries\";' src/api.ts" 'head -3 src/api.ts' "npm run build 2>&1 | grep 'assets/.*js'"
block restore
session '~/planner' 'git restore src/api.ts' 'git status --short'
quiet '~/planner' 'npm run build'
quiet '~/planner' 'git tag -f lesson-10'
bg_stop reg INT
