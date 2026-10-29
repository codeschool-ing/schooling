#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l5.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l5.txt; done
#
# It first puts ~/planner back as lesson 4 left it, from lessons 1 and 4's own
# files, so it can be run again. Files the lesson shows whole are taken out of
# it by lab/shown.py; the changes it shows as a fragment are made by lab/edit.sh
# with the fragment taken out of the lesson. The five thousand courses are
# gen.ts's, from lesson 3, written into dist/ as that lesson says.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
. ../../lab/edit.sh
L=$PWD; L1=$L/../le-3s959ek5; L4=$L/../le-3bzm1e2v
P=/home/ana/planner
for n in ssr str nx sv; do bg_stop $n; done
long_wait() { for _ in $(seq 900); do (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0; sleep 0.2; done; echo "nothing on $1" >&2; }
restart() { bg_stop ssr INT; bg ssr '~/planner' 'npm run build >/dev/null && TZ=UTC node server.ts'; long_wait 3000; }

# Lesson 4's planner.
for f in index.html src/style.css; do shown $L1/the-planner.md $f "~/planner/$f"; done
shown $L1/server-side.md server.ts '~/planner/server.ts'
edit $P/server.ts replace "  const html = shell.replace(" "$(fence $L4/hydrating-the-planner.md '// The plan goes into the page')"
shown $L4/hydrating-the-planner.md src/main.ts '~/planner/src/main.ts'
shown $L4/hydrating-the-planner.md src/view.ts '~/planner/src/view.ts'
edit $P/src/view.ts replace "const day = " "$(fence $L4/a-mismatch.md 'const day = ')"
quiet '~/planner' 'rm -f src/vitals.ts public/notice.json tools/vitals.ts; npm uninstall web-vitals'

block install
session '~/planner' 'npm install --save-exact web-vitals@6.2.3'
block thresholds
osession '~/planner' "grep -h 'Thresholds = ' node_modules/web-vitals/dist/modules/on*.js"
shown $L/measuring-the-planner.md src/vitals.ts '~/planner/src/vitals.ts'
shown $L/measuring-the-planner.md public/notice.json '~/planner/public/notice.json'
edit $P/index.html before '    <main id="app"></main>' "$(fence $L/measuring-the-planner.md '<p class="notice"')"
edit $P/src/style.css append - "$(fence $L/measuring-the-planner.md '.notice {')"
shown $L/measuring-the-planner.md src/main.ts '~/planner/src/main.ts'
shown $L/measuring-the-planner.md tools/vitals.ts '~/planner/tools/vitals.ts'
restart
block first
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/courses/git'

# The layout shift.
block shift
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/courses/git --phone --slow'
edit $P/src/style.css replace '.notice:empty' "$(fence $L/a-layout-shift.md '.notice:empty')"
restart
block room
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/courses/git --phone --slow'
shown $L/a-layout-shift.md server.ts '~/planner/server.ts'
restart
block server-notice
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/courses/git --phone --slow'

# The slow interaction.
INP='node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"'
block inp-slow
osession '~/planner' "$INP"
edit $P/src/view.ts replace-to 'export function homePage|  });' "$(fence $L/a-slow-interaction.md 'export function homePage')"
restart
block inp-count
osession '~/planner' "$INP"
edit $P/src/view.ts replace-to '  const courses = plan.courses.map|    `<li><a href' "$(fence $L/a-slow-interaction.md '// A page shows the first hundred')"
restart
block inp-less
osession '~/planner' "$INP"

# Field data.
edit $P/src/vitals.ts replace 'import { onCLS, onINP, onLCP }' "$(fence $L/field-data.md 'import { onCLS, onINP, onLCP, type Metric }')"
edit $P/src/vitals.ts append - "$(fence $L/field-data.md '// Once per page view')"
edit $P/server.ts after '  const { pathname } = new URL' "$(fence $L/field-data.md 'if (req.method === "POST"')"
restart
block field
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/courses/git --click "[data-done]"'
sleep 1
block field-log
bg_show ssr
bg_stop ssr INT
