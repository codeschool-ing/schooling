#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l12.txt
#   F="python3 ../../lab/fill.py"
#   $F routes-are-folders.md /tmp/l12.txt --blocks about
#   $F layouts.md /tmp/l12.txt --blocks layout-about,header
#   $F route-groups.md /tmp/l12.txt --blocks groups-mv,week
#   $F dynamic-routes.md /tmp/l12.txt --blocks course,persist,piano
#   $F matchers.md /tmp/l12.txt --blocks matcher-mv,algebra-404
#   $F errors.md /tmp/l12.txt --blocks error-page,status
#   $F navigation.md /tmp/l12.txt --blocks preload,lost
#
# It starts from the project as lesson 11 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 11

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown routes-are-folders.md src/routes/about/+page.svelte '~/planner/src/routes/about/+page.svelte'
sleep 1
block about
session '~/planner' "look http://localhost:5173/about --click 'Back to the planner'"

shown layouts.md src/routes/+layout.svelte '~/planner/src/routes/+layout.svelte'
shown layouts.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block layout-about
session '~/planner' 'look http://localhost:5173/about'
block header
session '~/planner' "curl -s http://localhost:5173/about | grep -o '<header.*</header>'"

block groups-mv
session '~/planner' "mkdir 'src/routes/(planner)' 'src/routes/(info)'" \
  "mv src/routes/about 'src/routes/(info)/about'" \
  "mv src/routes/+page.svelte 'src/routes/(planner)/+page.svelte'" \
  'mv src/lib/Planner.svelte src/lib/PlannerProvider.svelte' \
  "find src/routes -name '*.svelte' | sort"
shown route-groups.md src/lib/PlannerProvider.svelte '~/planner/src/lib/PlannerProvider.svelte'
shown route-groups.md 'src/routes/(planner)/+layout.svelte' '~/planner/src/routes/(planner)/+layout.svelte'
shown route-groups.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'
shown route-groups.md 'src/routes/(planner)/+page.svelte' '~/planner/src/routes/(planner)/+page.svelte'
sleep 2
block week
session '~/planner' 'look http://localhost:5173/'

shown dynamic-routes.md src/lib/planner.svelte.js '~/planner/src/lib/planner.svelte.js'
shown dynamic-routes.md 'src/routes/(planner)/courses/[id]/+page.svelte' '~/planner/src/routes/(planner)/courses/[id]/+page.svelte'
sleep 2
block course
session '~/planner' "look http://localhost:5173/ --click 'Spanish'"
block persist
session '~/planner' "look http://localhost:5173/courses/guitar --click 'Previous week' --fill 'Date=2026-10-14' --press Enter --click 'Study planner'"
block piano
session '~/planner' 'look http://localhost:5173/courses/piano'

shown matchers.md src/params.js '~/planner/src/params.js'
block matcher-mv
session '~/planner' "mv 'src/routes/(planner)/courses/[id]' 'src/routes/(planner)/courses/[id=slug]'"
sleep 2
block algebra-404
session '~/planner' 'look http://localhost:5173/courses/Algebra'

shown errors.md src/routes/+error.svelte '~/planner/src/routes/+error.svelte'
sleep 1
block error-page
session '~/planner' 'look http://localhost:5173/courses/Algebra'
block status
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:5173/courses/Algebra"

block preload
session '~/planner' 'grep -n sveltekit src/app.html'
block lost
session '~/planner' "look http://localhost:5173/courses/guitar --fill 'Date=2026-10-21' --press Enter --click 'About' --click 'Study planner'"
done_lesson 12 "routes: the week, a page per course, About, and an error page"
