#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 5's captures left, and saves what it
# leaves for lesson 7.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position), the try/ folder they go in included; `ng serve`, running "in
# a second terminal"; after each save, a wait until the dev server has
# finished the build it caused. The browser's date is set with look --today
# where the lesson says.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-xkvc03gn
serve
w() { rebuilt; }

save signal try/signals.mts
cap '~/planner' 'node try/signals.mts'
save computed try/computed.mts
cap '~/planner' 'node try/computed.mts'
save computed try/branches.mts
cap '~/planner' 'node try/branches.mts'
save equality try/equality.mts
cap '~/planner' 'node try/equality.mts'

save effect src/app/week-summary/week-summary.ts
save effect src/app/week-summary/week-summary.html; w
cap_look http://localhost:4200/ --text app-week-summary --do "'click Mark 15 minutes done'" --do "'click Mark 15 minutes done'"

save resource src/app/planner.ts
save resource src/app/week-summary/week-summary.ts 1
save resource src/app/week-summary/week-summary.html; w
cap_look http://localhost:4200/ --text app-week-summary --network
save resource src/app/week-summary/week-summary.ts 2; w
cap_look http://localhost:4200/ --text app-week-summary
save resource src/app/week-summary/week-summary.ts 3; w
cap_look http://localhost:4200/ --text app-week-summary --network

save the-week-computed src/app/planner.ts
save the-week-computed src/app/week-summary/week-summary.ts
save the-week-computed src/app/week-summary/week-summary.html
save the-week-computed src/app/week/week.ts
save the-week-computed src/app/week/week.html; w
cap_look http://localhost:4200/ --today 2026-10-23
cap_look http://localhost:4200/ --today 2026-10-28
cap_look http://localhost:4200/ --today 2026-10-23 --network
cap '~/planner' 'rm -r try'
cap '~/planner' 'npx ng test --watch=false 2>&1 | grep Tests'
cap '~/planner' 'git add -A && git commit -q -m "Signals: the week computed from the data"'

bg_stop serve
snapshot le-0z4qr9s9
