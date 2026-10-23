#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l12.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l12.txt; done
#
# Starts from the planner as lesson 11 left it (which is lesson 10's planner).
# Installs vue-router 5.4.0 from the npm registry. Every file of the planner
# is taken out of the section that shows it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh

files() {
  quiet $P 'grep -q vue-router package.json || npm install --silent --save-exact vue-router@5.4.0'
  shown installing.md src/main.js $P/src/main.js
  shown routes.md src/router.js $P/src/router.js
  shown routes.md src/keys.js $P/src/keys.js
  shown routes.md src/App.vue $P/src/App.vue
  shown routes.md src/views/HomeView.vue $P/src/views/HomeView.vue
  shown routes.md src/components/CourseCard.vue $P/src/components/CourseCard.vue
  shown params.md src/views/CourseView.vue $P/src/views/CourseView.vue
  shown nested.md src/views/CourseWeek.vue $P/src/views/CourseWeek.vue
  shown nested.md src/views/CourseAll.vue $P/src/views/CourseAll.vue
  shown guards.md src/views/NotFound.vue $P/src/views/NotFound.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-8zbqyvd4
block install
session $P 'npm install --save-exact vue-router@5.4.0'
files
quiet $P 'rm -rf dist'
dev pl $P 'npm run dev' 5173
block routes
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --text main"
block params
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --text main"
block nested
session $P "look http://localhost:5173/courses/spanish/all --clock 2026-10-21T10:00 --text main"
block aria
session $P "look http://localhost:5173/courses/spanish/all --html 'nav[aria-label=Sessions]' --text -"
block latin
session $P "look http://localhost:5173/courses/latin --text main"
block nowhere
session $P "look http://localhost:5173/nowhere/at/all --text '#app'"
block title
session $P "look http://localhost:5173/courses/spanish --html title --text -"
block lazy
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --text - --network"
block fallback
session $P "curl -s http://localhost:5173/courses/spanish | grep -E '<title>|id=\"app\"'"
bg_stop pl
block build
session $P 'npm run build'
block static
session $P 'cd dist && python3 -m http.server 8000 > /dev/null 2>&1 &' 'sleep 1; curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/' \
  'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/courses/spanish' 'kill %1'
snapshot
