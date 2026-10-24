#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 16's captures left, and saves what it
# leaves for lesson 18.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py; `ng serve` and `node server/api.mjs`, each in
# a terminal of its own, the API starting from seed.json; after each save, a
# wait until the dev server has finished the build it caused. The first page
# that imports @angular/core/rxjs-interop is reloaded once by the dev server,
# as lesson 12 shows; the student's own tab takes that reload, and a quiet
# look stands in for it.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-4e75ws11
quiet '~/planner' 'rm -f server/planner.json'
serve
w() { rebuilt; }
api() { bg api '~/planner' 'node server/api.mjs'; wait_port 3000; }
first_page() { quiet '~/planner' 'look http://localhost:4200/ --wait 2000'; }
api

cap '~/planner' 'npx ng generate component not-found --inline-template --inline-style --skip-tests'
save routes src/app/not-found/not-found.ts
save routes src/app/app.routes.ts
save routes src/app/app.config.ts
save routes src/app/app.html
save routes src/app/app.ts; w
cap_look http://localhost:4200/ --today 2026-10-23 --text main
cap_look http://localhost:4200/courses/git --text main
cap_look http://localhost:4200/nowhere --text main
cap '~/planner' 'curl -si http://localhost:4200/courses/git | head -1'

save links src/app/course-card/course-card.ts
save links src/app/app.html
save links src/app/app.ts
save links src/app/app.css; w
cap_look http://localhost:4200/ --today 2026-10-23 --text main --do "'click JavaScript'" --url
cap_look http://localhost:4200/ --html "'app-root nav'"
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|^ERROR|Tests '"
save links src/app/app.spec.ts
save links src/app/week/week.spec.ts
cap '~/planner' "npx ng test --watch=false 2>&1 | grep -E 'FAIL|^ERROR|Tests '"

cap_look http://localhost:4200/courses/rust --text main

cap '~/planner' 'npx ng generate component course-sessions --inline-template --inline-style --skip-tests'
save child-routes src/app/course-sessions/course-sessions.ts
save child-routes src/app/course-page/course-page.ts
save child-routes src/app/course-page/course-page.html
save child-routes src/app/course-page/course-page.css
save child-routes src/app/app.routes.ts
save child-routes src/app/app.config.ts
save child-routes src/app/add-session/add-session.ts; w
cap_look http://localhost:4200/courses/javascript --today 2026-10-23 --text main --do "'click Add sessions'" --url
cap_look http://localhost:4200/courses/javascript/add --today 2026-10-23 --text main --do "'fill Date 1 = 2026-10-26'" --do "'click Add'" --url

save redirects src/app/app.routes.ts; w
cap_look http://localhost:4200/week --url --text h2
cap_look http://localhost:4200/course/git --url --text h2

save titles src/app/course-title.ts
save titles src/app/app.routes.ts; w; first_page
cap_look http://localhost:4200/ --html title
cap_look http://localhost:4200/courses/git --html title
cap_look http://localhost:4200/nowhere --html title
cap '~/planner' 'git add -A && git commit -q -m "Router: a page per address, links, child routes, redirects and titles"'

bg_stop api
bg_stop serve
snapshot le-2qp8bb94
