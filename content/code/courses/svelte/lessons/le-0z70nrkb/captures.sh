#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l13.txt
#   F="python3 ../../lab/fill.py"
#   $F load-function.md /tmp/l13.txt --blocks no-title,title,fetched
#   $F server-load.md /tmp/l13.txt --blocks move,server-title,overlay,rename,week-back,json-404
#   $F over-the-wire.md /tmp/l13.txt --blocks data-json,status-500,dev-500
#   $F parent-and-errors.md /tmp/l13.txt --blocks piano,piano-status,guitar
#   $F where-it-runs.md /tmp/l13.txt --blocks direct,dev-direct,clicked,dev-clicked
#   $F rerunning.md /tmp/l13.txt --blocks moving,dev-moving
#
# It starts from the project as lesson 12 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 12

restart_dev() { bg_stop dev; bg dev '~/planner' 'npm run dev'; wait_port 5173; sleep 1; }
restart_dev

block no-title
session '~/planner' "curl -s http://localhost:5173/ | grep -c '<title>'"
shown load-function.md 'src/routes/(planner)/+layout.js' '~/planner/src/routes/(planner)/+layout.js'
shown load-function.md 'src/routes/(planner)/+layout.svelte' '~/planner/src/routes/(planner)/+layout.svelte'
sleep 2
block title
session '~/planner' "curl -s http://localhost:5173/ | grep -o '<title>.*</title>'"
block fetched
session '~/planner' "curl -s http://localhost:5173/ | grep -o '<script type=\"application/json\" data-sveltekit-fetched[^>]*>'"

block move
session '~/planner' 'mkdir data src/lib/server' 'git mv static/planner.json data/planner.json'
shown server-load.md src/lib/server/planner.js '~/planner/src/lib/server/planner.js'
shown server-load.md 'src/routes/(planner)/+layout.js' '~/planner/src/routes/(planner)/+layout.js'
sleep 2
block server-title
session '~/planner' "curl -s http://localhost:5173/ | grep -o '<title>.*</title>'"
block overlay
session '~/planner' 'look http://localhost:5173/'
block rename
session '~/planner' "mv 'src/routes/(planner)/+layout.js' 'src/routes/(planner)/+layout.server.js'"
shown server-load.md 'src/routes/(planner)/+layout.server.js' '~/planner/src/routes/(planner)/+layout.server.js'
sleep 2
block week-back
session '~/planner' 'look http://localhost:5173/ | head -4'
block json-404
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/planner.json"
block data-json
session '~/planner' 'curl -s http://localhost:5173/__data.json'

shown over-the-wire.md 'src/routes/(planner)/+layout.server.js' '~/planner/src/routes/(planner)/+layout.server.js'
restart_dev
block status-500
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/"
sleep 0.5
block dev-500
bg_show dev
shown server-load.md 'src/routes/(planner)/+layout.server.js' '~/planner/src/routes/(planner)/+layout.server.js'

shown parent-and-errors.md 'src/routes/(planner)/courses/[id=slug]/+page.js' '~/planner/src/routes/(planner)/courses/[id=slug]/+page.js'
shown parent-and-errors.md 'src/routes/(planner)/courses/[id=slug]/+page.svelte' '~/planner/src/routes/(planner)/courses/[id=slug]/+page.svelte'
sleep 2
block piano
session '~/planner' 'look http://localhost:5173/courses/piano'
block piano-status
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/courses/piano"
block guitar
session '~/planner' 'look http://localhost:5173/courses/guitar'

shown where-it-runs.md 'src/routes/(planner)/courses/[id=slug]/+page.js' '~/planner/src/routes/(planner)/courses/[id=slug]/+page.js'
restart_dev
block direct
session '~/planner' 'look http://localhost:5173/courses/spanish --console | grep -v vite'
sleep 0.5
block dev-direct
bg_show dev
block clicked
session '~/planner' 'look http://localhost:5173/ --console --click Spanish | grep -v vite | head -3'
sleep 0.5
block dev-clicked
bg_show dev

shown rerunning.md 'src/routes/(planner)/+layout.server.js' '~/planner/src/routes/(planner)/+layout.server.js'
restart_dev
block moving
session '~/planner' "look http://localhost:5173/ --console --click Spanish --click 'Study planner' --click Guitar | grep -v vite | head -6"
sleep 0.5
block dev-moving
bg_show dev
done_lesson 13 "load functions: the planner read on the server, a course page that 404s"
