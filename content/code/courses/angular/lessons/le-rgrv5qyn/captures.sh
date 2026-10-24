#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 8's captures left, and saves what it
# leaves for lesson 10.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve`, running "in a second terminal"; after each save,
# a wait until the dev server has finished the build it caused.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-zc1x61c7
serve
w() { rebuilt; }

cap '~/planner' 'npx ng generate component bench --inline-template --inline-style --skip-tests'
save the-hooks src/app/bench/bench.ts
save the-hooks src/app/app.html
save the-hooks src/app/app.ts; w
cap_look http://localhost:4200/ --text app-bench --do "'click Rename'" --do "'click Remove'"

save constructor-or-init src/app/bench/bench.ts; w
cap '~/planner' 'npx ng build 2>&1 | grep -A4 ERROR'

save destroy src/app/bench/bench.ts 1; w
# The dev server hands the error of the failed build above to the first page
# that connects after it, even once a build has succeeded. The student's own
# tab, open through all of it, is that page; this look stands in for it.
quiet '~/planner' 'look http://localhost:4200/'
cap_look http://localhost:4200/ --text app-bench --do "'wait 500'" --do "'click Remove'" --do "'wait 500'"
save destroy src/app/bench/bench.ts 2; w
cap_look http://localhost:4200/ --text app-bench --do "'wait 500'" --do "'click Remove'" --do "'wait 500'"

save after-render src/app/bench/bench.ts; w
cap_look http://localhost:4200/ --text app-bench

cap '~/planner' 'rm -r src/app/bench'
save which-you-need src/app/app.html
save which-you-need src/app/app.ts; w
cap '~/planner' 'git status --short'

bg_stop serve
snapshot le-rgrv5qyn
