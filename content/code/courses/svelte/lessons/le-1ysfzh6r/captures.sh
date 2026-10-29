#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l17.txt
#   F="python3 ../../lab/fill.py"
#   $F first-endpoint.md /tmp/l17.txt --blocks json
#   $F csv.md /tmp/l17.txt --blocks csv,csv-link
#   $F receiving-data.md /tmp/l17.txt --blocks api-201,api-400,form-400,api-415
#   $F negotiation.md /tmp/l17.txt --blocks neg-json,neg-html,neg-form
#   $F endpoint-or-action.md /tmp/l17.txt --blocks err-json
#
# It starts from the project as lesson 16 left it, back on the dev server.
# STAGED: the files ana writes, taken out of the lesson's .md by lab/shown.py;
# and, at the end, the data file put back as Git has it.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 16

bg_stop web; bg_stop dev
bg dev '~/planner' 'npm run dev'; wait_port 5173; sleep 1
C='src/routes/(planner)/courses/[id=slug]'

shown first-endpoint.md src/routes/planner.json/+server.js '~/planner/src/routes/planner.json/+server.js'
sleep 1.5
block json
session '~/planner' 'curl -si http://localhost:5173/planner.json | head -7'

shown csv.md "$C/sessions.csv/+server.js" "~/planner/$C/sessions.csv/+server.js"
shown csv.md "$C/+page.svelte" "~/planner/$C/+page.svelte"
sleep 1.5
block csv
session '~/planner' 'curl -si http://localhost:5173/courses/algebra/sessions.csv'
block csv-link
session '~/planner' 'look http://localhost:5173/courses/algebra | tail -3'

shown receiving-data.md src/lib/server/check.js '~/planner/src/lib/server/check.js'
shown receiving-data.md "$C/+page.server.js" "~/planner/$C/+page.server.js"
shown receiving-data.md src/routes/api/sessions/+server.js '~/planner/src/routes/api/sessions/+server.js'
sleep 1.5
block api-201
session '~/planner' "curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{\"course\":\"spanish\",\"date\":\"2026-10-24\",\"minutes\":20}' http://localhost:5173/api/sessions"
block api-400
session '~/planner' "curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{\"course\":\"spanish\",\"date\":\"2026-10-24\",\"minutes\":2}' http://localhost:5173/api/sessions"
block form-400
session '~/planner' "curl -s -H 'Accept: text/html' -d 'date=2026-10-24&minutes=2' 'http://localhost:5173/courses/spanish?/add' | grep -o '<p role=\"alert\">[^<]*</p>'"
block api-415
session '~/planner' "curl -s -w ' %{http_code}\n' -H 'Content-Type: text/plain' -d '{\"course\":\"spanish\",\"date\":\"2026-10-24\",\"minutes\":20}' http://localhost:5173/api/sessions"

shown negotiation.md "$C/+server.js" "~/planner/$C/+server.js"
sleep 1.5
block neg-json
session '~/planner' "curl -si -H 'Accept: application/json' http://localhost:5173/courses/guitar; echo"
block neg-html
session '~/planner' "curl -s -H 'Accept: text/html' http://localhost:5173/courses/guitar | grep -o '<title>.*</title>'"
block neg-form
session '~/planner' "look http://localhost:5173/courses/guitar --fill 'Date=2026-10-23' --click 'Add session' --wait 500 | sed -n 1,20p"

block err-json
session '~/planner' "curl -s -w '\n' http://localhost:5173/courses/piano/sessions.csv"

quiet '~/planner' 'git checkout data/planner.json; rm -f data/planner.json.new'
done_lesson 17 "endpoints: /planner.json, a CSV download, a JSON API, and a course as JSON"
