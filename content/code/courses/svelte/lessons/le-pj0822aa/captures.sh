#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l16.txt
#   F="python3 ../../lab/fill.py"
#   $F handle.md /tmp/l16.txt --blocks h-fail,h-build,h-use,h-log
#   $F headers.md /tmp/l16.txt --blocks hd-home,hd-about
#   $F locals.md /tmp/l16.txt --blocks lo-two,lo-log
#   $F handle-error.md /tmp/l16.txt --blocks he-away,he-default,he-log1,he-ref,he-log2,he-back,he-piano
#
# It starts from the project as lesson 15 left it, with the built server. STAGED:
# the files ana writes, taken out of the lesson's .md by lab/shown.py; the
# builds and restarts the lesson asks for without showing them; and, at the
# end, the data file put back as Git has it.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 15

bg_stop dev; bg_stop web
build() { quiet '~/planner' 'ORIGIN=http://localhost:3000 npm run build'; }
restart_web() { bg_stop web; bg web '~/planner' 'node build'; wait_port 3000; sleep 0.5; }

shown handle.md 'src/hooks.server.js#1' '~/planner/src/hooks.server.js'
block h-fail
session '~/planner' "ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A4 'SvelteKit error'"
shown handle.md 'src/hooks.server.js#2' '~/planner/src/hooks.server.js'
block h-build
session '~/planner' 'ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A3 Prerendering'
restart_web
block h-use
session '~/planner' "look http://localhost:3000/ --click Guitar --fill 'Date=2026-10-23' --click 'Add session' --wait 500 | sed -n 1,6p"
sleep 0.3
block h-log
bg_show web

shown headers.md src/hooks.server.js '~/planner/src/hooks.server.js'
build; restart_web
block hd-home
session '~/planner' 'curl -sI http://localhost:3000/'
block hd-about
session '~/planner' 'curl -sI http://localhost:3000/about'

shown locals.md src/hooks.server.js '~/planner/src/hooks.server.js'
build; restart_web
block lo-two
session '~/planner' 'curl -s -o /dev/null http://localhost:3000/ && curl -s -o /dev/null http://localhost:3000/courses/piano'
sleep 0.3
block lo-log
bg_show web

restart_web
block he-away
session '~/planner' 'mv data/planner.json data/planner.json.away'
block he-default
session '~/planner' 'look http://localhost:3000/'
sleep 0.3
block he-log1
bg_show web
shown handle-error.md src/hooks.server.js '~/planner/src/hooks.server.js'
shown handle-error.md src/routes/+error.svelte '~/planner/src/routes/+error.svelte'
build; restart_web
block he-ref
session '~/planner' 'look http://localhost:3000/'
sleep 0.3
block he-log2
bg_show web
block he-back
session '~/planner' 'mv data/planner.json.away data/planner.json'
block he-piano
session '~/planner' 'look http://localhost:3000/courses/piano | head -5'

bg_stop web
quiet '~/planner' 'git checkout data/planner.json; rm -f data/planner.json.new'
done_lesson 16 "hooks: a request log with ids, security headers, and handleError"
