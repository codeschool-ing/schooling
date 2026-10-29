#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l6.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l6.txt; done
#
# It first puts ~/planner back as lesson 5 left it, from lessons 1, 4 and 5's
# own files, so it can be run again. Files the lesson shows whole are taken out
# of it by lab/shown.py; the changes it shows as a fragment are made by
# lab/edit.sh with the fragment taken out of the lesson. CHROME_PATH is set in
# every terminal that runs Lighthouse, as the lesson says to, without being
# typed again in each transcript.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
. ../../lab/edit.sh
L=$PWD; L1=$L/../le-3s959ek5; L4=$L/../le-3bzm1e2v; L5=$L/../le-fa611g27
P=/home/ana/planner
for n in ssr str nx sv pv; do bg_stop $n; done
long_wait() { for _ in $(seq 900); do (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0; sleep 0.2; done; echo "nothing on $1" >&2; }
restart() { bg_stop ssr INT; bg ssr '~/planner' 'npm run build >/dev/null && TZ=UTC node server.ts'; long_wait 3000; }
LH='~/planner; export CHROME_PATH=$(node -e '"'"'import("playwright").then((p) => console.log(p.chromium.executablePath()))'"'"')'

# Lesson 5's planner: lesson 4's, then lesson 5's own changes.
for f in index.html src/style.css; do shown $L1/the-planner.md $f "~/planner/$f"; done
shown $L4/hydrating-the-planner.md src/view.ts '~/planner/src/view.ts'
edit $P/src/view.ts replace "const day = " "$(fence $L4/a-mismatch.md 'const day = ')"
shown $L5/measuring-the-planner.md src/vitals.ts '~/planner/src/vitals.ts'
shown $L5/measuring-the-planner.md public/notice.json '~/planner/public/notice.json'
edit $P/index.html before '    <main id="app"></main>' "$(fence $L5/measuring-the-planner.md '<p class="notice"')"
edit $P/src/style.css append - "$(fence $L5/measuring-the-planner.md '.notice {')"
edit $P/src/style.css replace '.notice:empty' "$(fence $L5/a-layout-shift.md '.notice:empty')"
shown $L5/measuring-the-planner.md src/main.ts '~/planner/src/main.ts'
shown $L5/measuring-the-planner.md tools/vitals.ts '~/planner/tools/vitals.ts'
shown $L5/a-layout-shift.md server.ts '~/planner/server.ts'
edit $P/src/view.ts replace-to 'export function homePage|  });' "$(fence $L5/a-slow-interaction.md 'export function homePage')"
edit $P/src/view.ts replace-to '  const courses = plan.courses.map|    `<li><a href' "$(fence $L5/a-slow-interaction.md '// A page shows the first hundred')"
edit $P/src/vitals.ts replace 'import { onCLS, onINP, onLCP }' "$(fence $L5/field-data.md 'import { onCLS, onINP, onLCP, type Metric }')"
edit $P/src/vitals.ts append - "$(fence $L5/field-data.md '// Once per page view')"
edit $P/server.ts after '  const { pathname } = new URL' "$(fence $L5/field-data.md 'if (req.method === "POST"')"
quiet '~/planner' 'rm -f tools/report.ts tools/trace.ts tools/waterfall.ts trace.json report.report.*; npm pkg delete scripts.lighthouse; npm uninstall lighthouse'

# Lighthouse.
block install
session '~/planner' 'npm install --save-exact --save-dev lighthouse@13.5.0'
block chrome
osession '~/planner' "export CHROME_PATH=\$(node -e 'import(\"playwright\").then((p) => console.log(p.chromium.executablePath()))')" 'echo $CHROME_PATH'
block script
osession '~/planner' "npm pkg set scripts.lighthouse='lighthouse --quiet --chrome-flags=--headless=new --only-categories=performance --output=json --output=html --output-path=report'"
shown $L/running-lighthouse.md tools/report.ts '~/planner/tools/report.ts'
restart
block first
osession "$LH" 'npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json'

# The heavy page.
block heavy
osession "$LH" 'node gen.ts 5000 && npm run lighthouse -- http://localhost:3000/ >/dev/null && node tools/report.ts report.report.json'
block sizes
osession '~/planner' 'curl -s http://localhost:3000/ | wc -c' 'curl -s http://localhost:3000/ | gzip | wc -c'
block methods
osession "$LH" "for m in simulate devtools; do for i in 1 2 3; do npm run lighthouse -- http://localhost:3000/ --throttling-method=\$m >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP'; done; done"
block requests
osession '~/planner' "node tools/report.ts report.report.json | grep 'request /'"

# Compression.
edit $P/server.ts replace 'import { createServer } from "node:http";' "$(fence $L/compressing.md 'import { createServer, type IncomingMessage')"
edit $P/server.ts after 'const esc = ' "$(fence $L/compressing.md '// Every answer goes through here.')"
edit $P/server.ts replace-to '      res.writeHead(200, { "content-type": types|      res.end(body);' "$(fence $L/compressing.md 'send(req, res, types')"
edit $P/server.ts replace-to '  res.writeHead(200, { "content-type": "text/html|  res.end(html);' "$(fence $L/compressing.md 'send(req, res, "text/html')"
restart
block headers
osession '~/planner' "curl -s -H 'accept-encoding: gzip' -o /dev/null -D - http://localhost:3000/ | sed '/^\\r\$/q'"
block compressed
osession "$LH" 'node gen.ts 5000 && npm run lighthouse -- http://localhost:3000/ >/dev/null && node tools/report.ts report.report.json'

# The trace.
shown $L/the-performance-panel.md tools/trace.ts '~/planner/tools/trace.ts'
block trace
osession '~/planner' 'node gen.ts 5000 && node tools/trace.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"'
block trace-noclick
osession '~/planner' 'node tools/trace.ts http://localhost:3000/courses/course-1 --cpu 4'
block trace-small
osession '~/planner' 'cp public/courses.json dist/ && node tools/trace.ts http://localhost:3000/courses/git --cpu 4'

# Waterfalls.
shown $L/waterfalls.md tools/waterfall.ts '~/planner/tools/waterfall.ts'
bg pv '~/planner' 'npx vite preview --port 4173 --strictPort'
long_wait 4173
block waterfall
osession '~/planner' 'node tools/waterfall.ts http://localhost:3000/courses/git --slow' 'node tools/waterfall.ts http://localhost:4173/courses/git --slow'
block preview
bg_show pv
bg_stop pv INT
bg_stop ssr INT
