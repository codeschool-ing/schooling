#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l9.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l9.txt; done
#
# It runs on the planner as lesson 8 left it, the commit tagged lesson-8, and
# tags what it leaves lesson-9. The registry from lesson 7 is started because
# `npm ci` fetches @planner/ui from it. STAGED: in "Trying it", the person
# opening the JavaScript course in a browser and pressing Mark done is a
# Playwright script (/tmp/fdlab/l9/click.cjs, run with the planner's own
# @playwright/test); the GraphQL server's terminal that follows is what that
# press produced.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
bg reg '~/registry' 'npx -y verdaccio@6.10.7 --config ./config.yaml'
wait_port 4873
quiet '~/planner' 'git switch -q main; git reset -q --hard lesson-8 && git clean -fdq && npm ci'

# The server.
shown the-schema.md api/schema.graphql '~/planner/api/schema.graphql'
block install
session '~/planner' 'npm install --save-dev --save-exact graphql@17.0.2 2>&1 | tail -1'
shown a-server-to-ask.md api/server.mjs '~/planner/api/server.mjs'
bg api '~/planner' 'node api/server.mjs'
wait_port 4000
sleep 0.5
block api-start
bg_show api
block curl
session '~/planner' "curl -s http://127.0.0.1:4000/graphql -H 'content-type: application/json' -d '{\"query\": \"{ courses { id title } }\"}'; echo"
shown a-server-to-ask.md api/ask.mjs '~/planner/api/ask.mjs'

ask() { block "$1"; shift; session '~/planner' "$@"; }
ask q-fields "node api/ask.mjs '{ course(id: \"javascript\") { title minutesPlanned sessions { date minutes done } } }'"
ask q-graph "node api/ask.mjs '{ course(id: \"git\") { sessions { date course { title } } } }'"
ask q-alias "node api/ask.mjs '{ js: course(id: \"javascript\") { minutesPlanned } git: course(id: \"git\") { minutesPlanned } }'"
ask q-null "node api/ask.mjs '{ course(id: \"rust\") { title } }'"
ask v-ok "node api/ask.mjs 'query CourseSessions(\$id: ID!) { course(id: \$id) { title sessions { date minutes } } }' '{\"id\": \"html-css\"}'"
ask v-missing "node api/ask.mjs 'query CourseSessions(\$id: ID!) { course(id: \$id) { title } }'"
ask e-typo "node api/ask.mjs '{ course(id: \"git\") { titel } }'"
ask e-run "node api/ask.mjs 'mutation { addSession(input: { course: \"rust\", date: \"2026-10-20\", minutes: 30 }) { id } }'"
ask m-done "node api/ask.mjs 'mutation MarkDone(\$id: Int!) { markDone(id: \$id) { id done course { title } } }' '{\"id\": 5}'"
ask m-add "node api/ask.mjs 'mutation AddSession(\$input: NewSession!) { addSession(input: \$input) { id date minutes done } }' '{\"input\": {\"course\": \"git\", \"date\": \"2026-10-20\", \"minutes\": 30}}'"
ask m-again "node api/ask.mjs '{ course(id: \"git\") { minutesPlanned } }'"
ask f-query "node api/ask.mjs 'query Planner { courses { id title sessions { ...SessionFields } } } fragment SessionFields on Session { id date minutes done course { id } }' | head -20"
ask f-mutation "node api/ask.mjs 'mutation MarkDone(\$id: Int!) { markDone(id: \$id) { ...SessionFields } } fragment SessionFields on Session { id date minutes done course { id } }' '{\"id\": 6}'"

# The planner as a client.
shown the-planner-asks.md src/vite-env.d.ts '~/planner/src/vite-env.d.ts'
block envdev
session '~/planner' "echo 'VITE_GRAPHQL_URL=/graphql' > .env.development"
for f in vite.config.ts src/graphql.ts src/queries.ts src/api.ts src/main.ts; do
  shown the-planner-asks.md $f "~/planner/$f"
done
bg_stop api INT
bg api2 '~/planner' 'node api/server.mjs'
wait_port 4000
bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
quiet '~/planner' 'NODE_PATH=$HOME/planner/node_modules node /tmp/fdlab/l9/click.cjs'
sleep 1
block restart
{ bg_show api; echo '^C'; bg_show api2; }
bg_stop dev INT
block build
session '~/planner' "npm run build > /dev/null && grep -c 'courses.json' dist/assets/*.js" "grep -c 'MarkDone' dist/assets/*.js"

# The check.
shown checking-queries.md src/queries.test.ts '~/planner/src/queries.test.ts'
block test
session '~/planner' "npx tsc && npm test 2>&1 | grep -E 'Test Files|Tests'"
block commit
session '~/planner' 'git add -A && git commit -qm "Read and save sessions through GraphQL when VITE_GRAPHQL_URL is set"'
block break
session '~/planner' "sed -i 's/    minutes\$/    minute/' src/queries.ts" \
  "npm test 2>&1 | grep -E 'Cannot query|Tests'"
block restore
session '~/planner' 'git restore src/queries.ts' 'git status --short'
bg_stop api2 INT
quiet '~/planner' 'git tag -f lesson-9'
bg_stop reg INT
