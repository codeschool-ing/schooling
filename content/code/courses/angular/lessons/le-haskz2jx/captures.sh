#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 22's captures left, and saves what it
# leaves for lesson 24.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve`, `node server/api.mjs` and the
# production server, each in a terminal of its own, the API starting from
# seed.json; after each save, a wait until the dev server has finished the
# build it caused. The first page that imports a package new to the browser
# is reloaded once by the dev server, as lesson 12 shows; the student's own
# tab takes that reload, and a quiet look stands in for it. The servers'
# clock: from this lesson a page is first drawn by Node, so the programs in
# the second terminals believe it is 23 October 2026, the morning `--today`
# gives the browser (lib.sh's server_today). Where the lesson says a terminal
# stays quiet, the script checks that it did, and says so if not.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-m3914gga
quiet '~/planner' 'rm -f server/planner.json'
server_today 2026-10-23
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; }
# rendered: until the dev server answers / with the week in the HTML. Just
# after it starts, Vite may still be preparing dependencies, and a page asked
# for then can arrive unrendered.
rendered() {
  for _ in $(seq 60); do
    bash "$LAB_SH" script 'curl -s http://localhost:4200/' | grep -q 'planned' && return 0
    sleep 0.5
  done
  echo "expect: the dev server never rendered the week" >&2
}
prod() { bg_stop prod; bg prod '~/planner' "${1:-node dist/planner/server/server.mjs}"; wait_port 4000; }
quiet_since() { # NAME TEXT COUNT: the terminal printed TEXT no more than COUNT times
  [ "$(grep -c -- "$2" $STATE/$1.log)" -le "$3" ] || echo "expect: $1 printed '$2' again" >&2
}
api; serve; first_page

# what-the-server-sends
cap_look http://localhost:4200/ --no-js --text body
cap '~/planner' "curl -s http://localhost:4200/ | sed -n '/<body>/,/<\/body>/p'"
bg_stop serve

# adding-ssr
cap '~/planner' 'npx ng add @angular/ssr@21.2.28 --skip-confirmation --interactive=false'
cap '~/planner' 'git diff package.json'
cap '~/planner' 'npm install --save-exact @angular/ssr@21.2.28 express@5.3.0 @types/express@5.0.6 @types/node@22.20.5'
cap '~/planner' "git diff package.json | grep '^[-+] '"
cap '~/planner' 'git status --short'
cap '~/planner' 'cat src/app/app.config.server.ts'

# render-modes
cap '~/planner' 'cat src/app/app.routes.server.ts'
cap '~/planner' "npx ng build 2>&1 | grep -E 'ERROR|Prerendered'"
save render-modes src/app/app.routes.server.ts
cap '~/planner' "npx ng build 2>&1 | grep -E 'ERROR|Prerendered'"

# hydration
serve; first_page; rendered
cap_look http://localhost:4200/ --no-js --text main
cap_look http://localhost:4200/ --today 2026-10-23 --network --text app-week-summary
cap '~/planner' "curl -s http://localhost:4200/ | grep -o '<script id=\"ng-state\"[^>]*>.\\{70\\}'"
cap '~/planner' "curl -s http://localhost:4200/ | grep -o 'jsaction=\"[^\"]*\"' | sort | uniq -c"
cap_bg serve
save hydration src/app/app.config.ts; w; first_page
n=$(grep -c 'NG02801\|XHR support' $STATE/serve.log)
quiet '~/planner' 'look http://localhost:4200/courses/javascript'
quiet_since serve 'NG02801\|XHR support' "$n"

# not-a-browser
bg_stop serve; serve
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions
cap_bg serve
save not-a-browser src/app/preferences.ts; w
n=$(grep -c 'Preferences will' $STATE/serve.log)
quiet '~/planner' 'look http://localhost:4200/courses/javascript'
quiet_since serve 'Preferences will' "$n"
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do "'check Hide sessions that are done'" --do "'go /courses/javascript'"
cap '~/planner' "curl -s http://localhost:4200/courses/javascript | grep -o '[A-Z][a-z][a-z] [0-9]* Oct, [^<]*'"
cap_look http://localhost:4200/courses/git/add --no-js --a11y "'app-add-session form'" "| head -5"
cap_look http://localhost:4200/courses/git/add --a11y "'app-add-session form'" "| head -9"

# status-codes
loop='for p in / /week /course/git /nowhere /courses/nope; do curl -s -o /dev/null -w "$p %{http_code} %{redirect_url}\n" http://localhost:4200$p; done'
cap '~/planner' "$loop"
save status-codes src/app/app.routes.ts
save status-codes src/app/not-found/not-found.ts; w
cap '~/planner' "$loop"
cap_look http://localhost:4200/courses/nope --text main

# allowed-hosts
cap '~/planner' "npx ng build 2>&1 | grep -E 'Initial total|Prerendered|Output location'"
cap '~/planner' 'ls dist/planner dist/planner/server'
prod
cap_bg prod
cap_look http://localhost:4000/ --no-js --text body
cap_bg prod
cap '~/planner' "npx ng config projects.planner.architect.build.options.security.allowedHosts '[\"localhost\"]'"
quiet '~/planner' 'npx ng build'; prod
cap_look http://localhost:4000/ --no-js --text app-week
cap '~/planner' "curl -s -i -H 'Host: evil.example' http://localhost:4000/ | head -1"

# the-planners-server
cap '~/planner' 'curl -s -i http://localhost:4000/api/planner | head -1'
save the-planners-server src/server.ts
quiet '~/planner' 'npx ng build'; prod 'npm run serve:ssr:planner'
cap_look http://localhost:4000/courses/javascript --today 2026-10-23 --network --text app-course-sessions --do "'check Sat 24 Oct, 50 minutes'"
quiet '~/planner' "look http://localhost:4000/courses/javascript --do 'check Sat 24 Oct, 50 minutes'"
bg_stop api
cap_look http://localhost:4000/ --today 2026-10-23 --no-js --text app-week
sleep 1
grep -q 'did not answer' $STATE/prod.log || echo "expect: the server did not report the API" >&2
cap_bg prod
api
cap '~/planner' 'git add -A && git commit -q -m "SSR: the planner is rendered on the server"'

bg_stop prod
bg_stop api
bg_stop serve
snapshot le-haskz2jx
