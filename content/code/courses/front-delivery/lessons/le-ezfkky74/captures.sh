#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l11.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l11.txt; done
#
# It runs on the planner as lesson 10 left it, the commit tagged lesson-10, and
# tags what it leaves lesson-11. The registry from lesson 7 is started because
# `npm ci` fetches @planner/ui from it. STAGED: two browser visits are
# Playwright scripts run with the planner's own @playwright/test. In "The
# first report", /tmp/fdlab/l10/rollback.cjs opens the JavaScript course on
# the dev server, stops the GraphQL server and presses Mark done, as lesson 10
# did. In "A build like the real one", /tmp/fdlab/l11/crash.cjs opens
# http://localhost:4173/course/git?bug on `vite preview` and waits two
# seconds. The reports those visits produced, and everything after them, are
# what the page and the collector did.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
bg reg '~/registry' 'npx -y verdaccio@6.10.7 --config ./config.yaml'
wait_port 4873
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-10 && git clean -fdq && npm ci'

# Catching what escapes.
shown catching-what-escapes.md src/monitor.ts '~/planner/src/monitor.ts'
shown catching-what-escapes.md src/vite-env.d.ts '~/planner/src/vite-env.d.ts'
block main
session '~/planner' "sed -i 's#^import { saveDone, watch } from \"./api\";#&\nimport { report, watchErrors } from \"./monitor\";#' src/main.ts" \
  "sed -i 's#^const base = import.meta.env.BASE_URL;#watchErrors();\n\n&#' src/main.ts" \
  "sed -i 's#console.error(\"Could not save\", error)#report(error, \"saveDone\")#; s#console.error(\"Could not load\", error)#report(error, \"load\")#' src/main.ts" \
  "grep -n 'report\|watchErrors' src/main.ts"
block apollo
session '~/planner' "sed -i 's#^import type { Planner } from \"./api\";#&\nimport { report } from \"./monitor\";#' src/apollo.ts" \
  "sed -i 's#console.error(\"Could not load\", result.error)#report(result.error, \"Planner\")#' src/apollo.ts" \
  "grep -n 'report' src/apollo.ts" 'npx tsc && echo types ok'
block check-against-prototype
session '~/planner' 'diff src/main.ts /tmp/fdlab/l11/src/main.ts && diff src/apollo.ts /tmp/fdlab/l11/src/apollo.ts && echo same'

# The collector.
shown a-collector.md api/collector.mjs '~/planner/api/collector.mjs'
shown a-collector.md vite.config.ts '~/planner/vite.config.ts'
block envdev
session '~/planner' "printf 'VITE_GRAPHQL_URL=/graphql\nVITE_ERRORS_URL=/errors\n' > .env.development" \
  "printf 'api/errors.jsonl\nmaps\n' >> .gitignore"
bg api '~/planner' 'node api/server.mjs'
bg col '~/planner' 'node api/collector.mjs'
wait_port 4000
wait_port 4001
bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
block observed-first
bash ../../lab.sh script "cd ~/planner; NODE_PATH=\$HOME/planner/node_modules node /tmp/fdlab/l10/rollback.cjs $STATE/api.pid" 2>&1
sleep 0.5
block col-first
bg_show col
block tail
session '~/planner' 'tail -1 api/errors.jsonl'
bg_stop dev INT
bg api2 '~/planner' 'node api/server.mjs'
wait_port 4000

# A production stack.
block commit
session '~/planner' 'git add -A && git commit -qm "Report errors to a collector"'
block bug
session '~/planner' "sed -i 's/^function render(): void {/&\n  if (location.search === \"?bug\") throw new Error(\"A bug, on purpose\");/' src/main.ts"
block build
session '~/planner' 'VITE_GRAPHQL_URL=/graphql VITE_ERRORS_URL=/errors VITE_RELEASE=$(git rev-parse --short HEAD) npm run build 2>&1 | grep assets/'
bg preview '~/planner' 'npx vite preview --port 4173 --strictPort'
wait_port 4173
sleep 1
block observed-second
bash ../../lab.sh script "cd ~/planner; NODE_PATH=\$HOME/planner/node_modules node /tmp/fdlab/l11/crash.cjs 'http://localhost:4173/course/git?bug'" 2>&1 | head -3
sleep 0.5
block col-second
bg_show col
block report
session '~/planner' "tail -1 api/errors.jsonl | node -e 'process.stdin.on(\"data\", (d) => { const r = JSON.parse(d); console.log(r.release, r.source, r.path); console.log(r.stack); })'"
bg_stop preview INT

# Source maps.
block hidden
session '~/planner' 'tail -c 120 dist/assets/index-*.js; echo; ls dist/assets/'
block maps
session '~/planner' 'release=$(git rev-parse --short HEAD); mkdir -p maps/$release && mv dist/assets/*.map maps/$release/ && ls maps/$release'
shown source-maps.md api/symbolicate.mjs '~/planner/api/symbolicate.mjs'
block symbolicate
session '~/planner' "tail -1 api/errors.jsonl | node -e 'process.stdin.on(\"data\", (d) => console.log(JSON.parse(d).stack))' | node api/symbolicate.mjs maps/\$(git rev-parse --short HEAD)"
block restore
session '~/planner' 'git restore src/main.ts' 'git status --short'

# Counting.
block count
session '~/planner' "grep -o '\"message\":\"[^\"]*\"' api/errors.jsonl | sort | uniq -c | sort -rn"

bg_stop col INT
bg_stop api2 INT
quiet '~/planner' 'git add -A && git commit -qm "Turn stacks back into source lines" && git tag -f lesson-11'
bg_stop reg INT
