#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l14.txt
#   F="python3 ../../lab/fill.py"
#   $F without-javascript.md /tmp/l14.txt --blocks nojs-week,nojs-add
#   $F default-action.md /tmp/l14.txt --blocks da-add,da-tail,da-303
#   $F validation.md /tmp/l14.txt --blocks va-browser,va-bad,va-believed,va-checkout,va-fail
#   $F named-actions.md /tmp/l14.txt --blocks na-done
#   $F week-in-address.md /tmp/l14.txt --blocks wa-lost,wa-bite,wa-nojs,wa-arrow
#   $F use-enhance.md /tmp/l14.txt --blocks ue-add,ue-dev,ue-curl
#
# It starts from the project as lesson 13 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; and, at the end, the
# data file put back as Git has it, so that the sessions these transcripts
# added do not follow the project into lesson 15.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 13

restart_dev() { bg_stop dev; bg dev '~/planner' 'npm run dev'; wait_port 5173; sleep 1; }
C='src/routes/(planner)/courses/[id=slug]'
restart_dev

block nojs-week
session '~/planner' "look http://localhost:5173/courses/guitar --no-js --click 'Previous week'"
block nojs-add
session '~/planner' "look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-21' --click 'Add session'"

shown saving.md 'src/routes/(planner)/+layout.server.js' '~/planner/src/routes/(planner)/+layout.server.js'
shown saving.md "$C/+page.js" "~/planner/$C/+page.js"
shown saving.md src/lib/server/planner.js '~/planner/src/lib/server/planner.js'
shown default-action.md "$C/+page.server.js#1" "~/planner/$C/+page.server.js"
shown default-action.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
shown default-action.md "$C/+page.svelte" "~/planner/$C/+page.svelte"
sleep 2
block da-add
session '~/planner' "look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-21' --click 'Add session'"
block da-tail
session '~/planner' 'tail -8 data/planner.json'
shown default-action.md "$C/+page.server.js#2" "~/planner/$C/+page.server.js"
sleep 1.5
block da-303
session '~/planner' "curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' -H 'Accept: text/html' -d 'date=2026-10-23&minutes=30' http://localhost:5173/courses/guitar"

block va-browser
session '~/planner' "look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-22' --fill 'Minutes=3' --click 'Add session'"
block va-bad
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-10-22&minutes=-40' http://localhost:5173/courses/guitar"
block va-believed
session '~/planner' 'look http://localhost:5173/courses/guitar | grep min'
block va-checkout
session '~/planner' 'git checkout data/planner.json'
shown validation.md "$C/+page.server.js" "~/planner/$C/+page.server.js"
shown validation.md src/lib/week.js '~/planner/src/lib/week.js'
shown validation.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
sleep 2
block va-fail
session '~/planner' "curl -s -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-02-31&minutes=30' http://localhost:5173/courses/guitar | grep -o '<p role=\"alert\">[^<]*</p>\|^[0-9]*$'"

shown named-actions.md "$C/+page.server.js" "~/planner/$C/+page.server.js"
shown named-actions.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
shown named-actions.md "$C/+page.svelte" "~/planner/$C/+page.svelte"
sleep 2
block na-done
session '~/planner' "look http://localhost:5173/courses/algebra --no-js --click 'Mark done: 24 Oct 2026'"

block wa-lost
session '~/planner' "look http://localhost:5173/courses/spanish --click 'Previous week' --click 'Mark not done: 15 Oct 2026'"
shown week-in-address.md 'src/routes/(planner)/+layout.js' '~/planner/src/routes/(planner)/+layout.js'
shown week-in-address.md src/lib/WeekNav.svelte '~/planner/src/lib/WeekNav.svelte'
sleep 2
block wa-bite
session '~/planner' "look http://localhost:5173/ --click 'Next week'"
shown week-in-address.md src/lib/planner.svelte.js '~/planner/src/lib/planner.svelte.js'
shown week-in-address.md src/lib/PlannerProvider.svelte '~/planner/src/lib/PlannerProvider.svelte'
shown week-in-address.md src/lib/context.js '~/planner/src/lib/context.js'
shown week-in-address.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'
shown week-in-address.md 'src/routes/(planner)/+page.svelte' '~/planner/src/routes/(planner)/+page.svelte'
shown week-in-address.md "$C/+page.server.js" "~/planner/$C/+page.server.js"
shown week-in-address.md "$C/+page.svelte" "~/planner/$C/+page.svelte"
sleep 2
block wa-nojs
session '~/planner' "look http://localhost:5173/ --no-js --click 'Previous week' --click 'Guitar' --fill 'Date=2026-10-14' --click 'Add session'"
block wa-arrow
session '~/planner' "look 'http://localhost:5173/?week=2026-10-19' --press ArrowLeft --wait 300 | head -10"

shown use-enhance.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
shown use-enhance.md "$C/+page.svelte" "~/planner/$C/+page.svelte"
restart_dev
block ue-add
session '~/planner' "look http://localhost:5173/courses/guitar --fill 'Date=2026-10-21' --click 'Add session' --wait 500"
sleep 0.5
block ue-dev
bg_show dev
block ue-curl
session '~/planner' "curl -s -w '\n' -d 'date=2026-10-22&minutes=30' 'http://localhost:5173/courses/guitar?week=2026-10-19&/add'"

quiet '~/planner' 'git checkout data/planner.json; rm -f data/planner.json.new'
done_lesson 14 "form actions: sessions saved on the server, the week in the address, use:enhance"
