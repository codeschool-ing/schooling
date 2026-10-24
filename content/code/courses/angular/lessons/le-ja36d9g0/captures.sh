#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of angular, as a script that
# produces them. The output is not committed: lab/fill.py pastes it into the
# lesson's fences.
#
#   sudo bash captures.sh > out.txt && python3 ../../lab/fill.py <section>.md out.txt
#
# It starts from the ~/planner lesson 3's captures left, and saves what it
# leaves for lesson 5.
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (a file shown twice in one section is taken by
# its position); `ng serve`, running "in a second terminal". After each save
# the script waits until the dev server has finished the build it caused, as a
# person would before looking.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-37z2c925
serve
w() { rebuilt; }

cap '~/planner' 'npx ng generate component bench --skip-tests'
save interpolation src/app/app.html
save interpolation src/app/app.ts
save interpolation src/app/bench/bench.ts
save interpolation src/app/bench/bench.html; w
cap_look http://localhost:4200/ --text app-bench

save property-binding src/app/bench/bench.html 1; w
cap_look http://localhost:4200/ --a11y app-bench
cap_look http://localhost:4200/ --html app-bench
save property-binding src/app/bench/bench.html 2
cap '~/planner' 'npx ng build 2>&1 | grep -A1 ERROR'

save class-and-style src/app/bench/bench.css
save class-and-style src/app/bench/bench.html; w
cap_look http://localhost:4200/ --html app-bench

save event-binding src/app/bench/bench.ts
save event-binding src/app/bench/bench.html; w
cap_look http://localhost:4200/ --text app-bench --do "'click Add 15'" --do "'click Add 15'" --do "'fill Minutes = 100'" --do "'fill Note = revise the router'" --do "'press Enter'"

save checked-templates src/app/bench/bench.html
cap '~/planner' 'npx ng build 2>&1 | grep -A1 ERROR'

save the-week-in-numbers src/app/week-summary/week-summary.ts
save the-week-in-numbers src/app/week-summary/week-summary.html
cap '~/planner' 'rm -r src/app/bench'
save the-week-in-numbers src/app/app.html 1
save the-week-in-numbers src/app/app.ts; w
cap_look http://localhost:4200/ --a11y main
save the-week-in-numbers src/app/app.html 2; w
cap_look http://localhost:4200/ --a11y main
cap '~/planner' 'npx ng test --watch=false 2>&1 | grep Tests'
cap '~/planner' 'git add -A && git commit -q -m "Bindings: the week'"'"'s numbers and its progress bar"'

bg_stop serve
snapshot le-ja36d9g0
