#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l8.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l8.txt; done
#
# It first puts ~/planner back as lesson 7 left it, from lessons 1 and 4 to 7's
# own files, and lesson 2's Angular project's routes as lesson 2 wrote them, so
# it can be run again. Files the lesson shows whole are taken out of it by
# lab/shown.py; the changes it shows as a fragment are made by lab/edit.sh with
# the fragment taken out of the lesson.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
. ../../lab/edit.sh
L=$PWD; L1=$L/../le-3s959ek5; L2=$L/../le-7gh59h40; L4=$L/../le-3bzm1e2v; L5=$L/../le-fa611g27; L6=$L/../le-2ek1kvv8; L7=$L/../le-vzsqtc54
P=/home/ana/planner
for n in ssr str nx sv pv; do bg_stop $n; done
long_wait() { for _ in $(seq 900); do (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0; sleep 0.2; done; echo "nothing on $1" >&2; }
restart() { bg_stop ssr INT; bg ssr '~/planner' 'npm run build >/dev/null && TZ=UTC node server.ts'; long_wait 3000; }

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
# Lesson 6's own changes.
shown $L6/running-lighthouse.md tools/report.ts '~/planner/tools/report.ts'
edit $P/server.ts replace 'import { createServer } from "node:http";' "$(fence $L6/compressing.md 'import { createServer, type IncomingMessage')"
edit $P/server.ts after 'const esc = ' "$(fence $L6/compressing.md '// Every answer goes through here.')"
edit $P/server.ts replace-to '      res.writeHead(200, { "content-type": types|      res.end(body);' "$(fence $L6/compressing.md 'send(req, res, types')"
edit $P/server.ts replace-to '  res.writeHead(200, { "content-type": "text/html|  res.end(html);' "$(fence $L6/compressing.md 'send(req, res, "text/html')"
shown $L6/the-performance-panel.md tools/trace.ts '~/planner/tools/trace.ts'
shown $L6/waterfalls.md tools/waterfall.ts '~/planner/tools/waterfall.ts'
quiet '~/planner' "npm pkg set scripts.lighthouse='lighthouse --quiet --chrome-flags=--headless=new --only-categories=performance --output=json --output=html --output-path=report'"
# Lesson 7's own changes.
shown $L7/a-cover-picture.md tools/covers.ts '~/planner/tools/covers.ts'
shown $L7/sizes-and-formats.md tools/images.ts '~/planner/tools/images.ts'
quiet '~/planner' 'rm -rf public/covers public/fonts; node tools/covers.ts && node tools/images.ts'
edit $P/src/view.ts replace '<h1>${esc(course.title)}</h1>' "$(fence $L7/a-cover-picture.md '<h1>${esc(course.title)}</h1>')"
edit $P/src/style.css append - "$(fence $L7/a-cover-picture.md '.cover {')"
edit $P/src/view.ts after 'const day = ' "$(fence $L7/srcset-and-sizes.md '// The cover in three widths')"
edit $P/src/view.ts replace '<img class="cover" src="/covers/${esc(course.slug)}.png" alt="">' "$(fence $L7/srcset-and-sizes.md '${cover(course.slug)}')"
edit $P/src/view.ts replace '  <img class="cover" src="/covers/${slug}-800.jpg"' "$(fence $L7/the-lcp-image.md '<img class="cover" src="/covers/${slug}-800.jpg"')"
quiet '~/planner' 'mkdir -p public/fonts && for w in 400 700; do cp node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-$w-normal.woff2 public/fonts/plex-$w.woff2; done'
edit $P/src/style.css append - "$(fence $L7/web-fonts.md '@font-face { font-family: "IBM Plex Sans"')"
quiet '~/planner' 'sed -i "s/font-display: block/font-display: swap/" src/style.css'
edit $P/index.html before '    <title>Study planner</title>' "$(fence $L7/web-fonts.md '<link rel="preload" href="/fonts')"
edit $P/src/style.css append - "$(fence $L7/a-fallback-that-fits.md '@font-face { font-family: "Plex fallback"')"
edit $P/src/style.css replace 'body { font:' "$(fence $L7/a-fallback-that-fits.md 'body { font: 16px/1.5 "IBM Plex Sans", "Plex fallback"')"
edit $P/server.ts replace 'const shell = await readFile(join(dist, "index.html"), "utf8");' "$(fence $L7/critical-css.md '// The shell the build wrote')"
quiet '~/planner' 'rm -f src/chart.ts tools/unused.ts tools/after-click.ts; npm uninstall chart.js'
shown $L2/angular.md src/app/app.routes.ts '~/meta/angular/src/app/app.routes.ts'
restart

# One file for every page.
block build-one
osession '~/planner' 'npm run build'
shown $L/one-file.md tools/unused.ts '~/planner/tools/unused.ts'
block unused-one
osession '~/planner' 'node tools/unused.ts http://localhost:3000/courses/git'

# A feature only one page uses.
block chartjs
session '~/planner' 'npm install --save-exact chart.js@4.5.1'
shown $L/a-feature-one-page-uses.md src/chart.ts '~/planner/src/chart.ts'
edit $P/src/view.ts before '// The page an address names' "$(fence $L/a-feature-one-page-uses.md '// The minutes of every week')"
edit $P/src/view.ts replace-to '// The page an address names|}' "$(fence $L/a-feature-one-page-uses.md '// The page an address names')"
edit $P/src/view.ts replace '<h2>Weeks</h2>' "$(fence $L/a-feature-one-page-uses.md '<h2>Weeks</h2>')"
edit $P/src/view.ts replace-to 'export function mount(|  const draw = ' "$(fence $L/a-feature-one-page-uses.md 'export function mount(')"
edit $P/src/view.ts replace-to '  if (!root.firstElementChild) {|  document.documentElement.dataset.hydrated' "$(fence $L/a-feature-one-page-uses.md 'if (!root.firstElementChild) {')"
edit $P/src/main.ts after 'import { mount } from "./view.ts";' "$(fence $L/a-feature-one-page-uses.md 'import { showChart }')"
edit $P/src/main.ts replace 'mount(document.querySelector' "$(fence $L/a-feature-one-page-uses.md 'mount(document.querySelector')"
block build-auto
osession '~/planner' 'npm run build'
restart
block unused-auto
osession '~/planner' 'node tools/unused.ts http://localhost:3000/courses/git' 'node tools/unused.ts http://localhost:3000/stats'

# Importing less.
edit $P/src/chart.ts replace 'import { Chart } from "chart.js/auto";' "$(fence $L/importing-less.md '// Only the pieces a bar chart uses')"
block build-less
osession '~/planner' 'npm run build'
restart
block unused-less
osession '~/planner' 'node tools/unused.ts http://localhost:3000/stats'

# On demand.
quiet '~/planner' 'sed -i "/^import { showChart } from \".\/chart.ts\";$/d" src/main.ts'
edit $P/src/main.ts replace-to 'mount(document.querySelector|});' "$(fence $L/import-on-demand.md 'mount(document.querySelector')"
block build-split
osession '~/planner' 'npm run build'
restart
block unused-split
osession '~/planner' 'node tools/unused.ts http://localhost:3000/courses/git' 'node tools/unused.ts http://localhost:3000/stats'
block waterfall-split
osession '~/planner' 'node tools/waterfall.ts http://localhost:3000/stats --slow'
block modulepreload
osession '~/planner' "grep -o '<link rel=\"modulepreload\"[^>]*>' dist/index.html"

# When to fetch it.
shown $L/when-to-fetch-it.md tools/after-click.ts '~/planner/tools/after-click.ts'
block click-cold
osession '~/planner' 'node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow'
edit $P/src/main.ts after '});' "$(fence $L/when-to-fetch-it.md '// A pointer resting on the link')"
restart
block click-warm
osession '~/planner' 'node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow' 'node tools/after-click.ts http://localhost:3000/ "text=Minutes per week" --slow --hover 300'

# The plan in the page.
block plan-size
osession '~/planner' "curl -s --compressed -o /dev/null -w '%{size_download} bytes\\n' http://localhost:3000/courses/git" "node gen.ts 5000 && curl -s --compressed -o /dev/null -w '%{size_download} bytes\\n' http://localhost:3000/courses/course-1"
bg_stop ssr INT

# Angular's routes.
block ng-eager
osession '~/meta/angular' "npm run build 2>&1 | sed -n '/Browser bundles/,/Server bundles/p' | grep -E '\\.js |Initial total|Lazy chunk'"
shown $L/routes-in-the-frameworks.md src/app/app.routes.ts '~/meta/angular/src/app/app.routes.ts'
block ng-lazy
osession '~/meta/angular' "npm run build 2>&1 | sed -n '/Browser bundles/,/Server bundles/p' | grep -E '\\.js |Initial total|Lazy chunk'"
