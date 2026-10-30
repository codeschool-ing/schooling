#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l7.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l7.txt; done
#
# It first puts ~/planner back as lesson 6 left it, from lessons 1, 4, 5 and
# 6's own files, so it can be run again. Files the lesson shows whole are taken
# out of it by lab/shown.py; the changes it shows as a fragment are made by
# lab/edit.sh with the fragment taken out of the lesson. CHROME_PATH is set in
# every terminal that runs Lighthouse, as lesson 6 says to, without being typed
# again in each transcript. The covers' grain is random, so their sizes move a
# little from one run to the next.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
. ../../lab/edit.sh
L=$PWD; L1=$L/../le-3s959ek5; L4=$L/../le-3bzm1e2v; L5=$L/../le-fa611g27; L6=$L/../le-2ek1kvv8
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
# Lesson 6's own changes.
shown $L6/running-lighthouse.md tools/report.ts '~/planner/tools/report.ts'
edit $P/server.ts replace 'import { createServer } from "node:http";' "$(fence $L6/compressing.md 'import { createServer, type IncomingMessage')"
edit $P/server.ts after 'const esc = ' "$(fence $L6/compressing.md '// Every answer goes through here.')"
edit $P/server.ts replace-to '      res.writeHead(200, { "content-type": types|      res.end(body);' "$(fence $L6/compressing.md 'send(req, res, types')"
edit $P/server.ts replace-to '  res.writeHead(200, { "content-type": "text/html|  res.end(html);' "$(fence $L6/compressing.md 'send(req, res, "text/html')"
shown $L6/the-performance-panel.md tools/trace.ts '~/planner/tools/trace.ts'
shown $L6/waterfalls.md tools/waterfall.ts '~/planner/tools/waterfall.ts'
quiet '~/planner' "npm pkg set scripts.lighthouse='lighthouse --quiet --chrome-flags=--headless=new --only-categories=performance --output=json --output=html --output-path=report'"
quiet '~/planner' 'rm -rf public/covers public/fonts tools/covers.ts tools/images.ts tools/chosen.ts tools/fallback.ts; npm uninstall sharp @fontsource/ibm-plex-sans'

# The cover, as it was handed over.
block sharp
session '~/planner' 'npm install --save-exact --save-dev sharp@0.35.5'
shown $L/a-cover-picture.md tools/covers.ts '~/planner/tools/covers.ts'
block covers
osession '~/planner' 'node tools/covers.ts'
edit $P/src/view.ts replace '<h1>${esc(course.title)}</h1>' "$(fence $L/a-cover-picture.md '<h1>${esc(course.title)}</h1>')"
edit $P/src/style.css append - "$(fence $L/a-cover-picture.md '.cover {')"
restart
block lh-png
osession "$LH" 'npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json'

# Sizes, formats and the markup that chooses.
shown $L/sizes-and-formats.md tools/images.ts '~/planner/tools/images.ts'
block images
osession '~/planner' 'node tools/images.ts'
edit $P/src/view.ts after 'const day = ' "$(fence $L/srcset-and-sizes.md '// The cover in three widths')"
edit $P/src/view.ts replace '<img class="cover" src="/covers/${esc(course.slug)}.png" alt="">' "$(fence $L/srcset-and-sizes.md '${cover(course.slug)}')"
shown $L/srcset-and-sizes.md tools/chosen.ts '~/planner/tools/chosen.ts'
restart
block chosen
osession '~/planner' 'node tools/chosen.ts http://localhost:3000/courses/git'
block lh-avif
osession "$LH" "npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight'"

# The LCP image: its room and its priority, measured with the browser really slowed.
DEV="npm run lighthouse -- http://localhost:3000/courses/git --throttling-method=devtools >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight|cover'"
block dev-before
osession "$LH" "$DEV"
edit $P/src/view.ts replace '  <img class="cover" src="/covers/${slug}-800.jpg"' "$(fence $L/the-lcp-image.md '<img class="cover" src="/covers/${slug}-800.jpg"')"
restart
block dev-after
osession "$LH" "$DEV"

# A web font.
block fontsource
session '~/planner' 'npm install --save-exact --save-dev @fontsource/ibm-plex-sans@5.3.0'
block copy
osession '~/planner' 'mkdir -p public/fonts && for w in 400 700; do cp node_modules/@fontsource/ibm-plex-sans/files/ibm-plex-sans-latin-$w-normal.woff2 public/fonts/plex-$w.woff2; done'
edit $P/src/style.css replace 'body { font:' "$(fence $L/web-fonts.md 'body { font: 16px/1.5 "IBM Plex Sans", system-ui')"
edit $P/src/style.css append - "$(fence $L/web-fonts.md '@font-face { font-family: "IBM Plex Sans"')"
restart
block font-block
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/ --phone --slow'
block font-waterfall
osession '~/planner' 'node tools/waterfall.ts http://localhost:3000/ --slow'
quiet '~/planner' 'sed -i "s/font-display: block/font-display: swap/" src/style.css'
restart
block font-swap
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/ --phone --slow'
edit $P/index.html before '    <title>Study planner</title>' "$(fence $L/web-fonts.md '<link rel="preload" href="/fonts')"
restart
block font-preload
osession '~/planner' 'node tools/vitals.ts http://localhost:3000/ --phone --slow'

# A fallback that fits.
shown $L/a-fallback-that-fits.md tools/fallback.ts '~/planner/tools/fallback.ts'
block fallback
osession '~/planner' 'node tools/fallback.ts http://localhost:3000/ "DejaVu Sans"' 'node tools/fallback.ts http://localhost:3000/ "Arial"'
edit $P/src/style.css append - "$(fence $L/a-fallback-that-fits.md '@font-face { font-family: "Plex fallback"')"
edit $P/src/style.css replace 'body { font:' "$(fence $L/a-fallback-that-fits.md 'body { font: 16px/1.5 "IBM Plex Sans", "Plex fallback"')"
restart
block fallback-adjusted
osession '~/planner' 'node tools/fallback.ts http://localhost:3000/ "Arial"'

# Critical CSS.
CSS="npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|FCP|LCP|insight'"
block css-before
osession "$LH" "$CSS"
edit $P/server.ts replace 'const shell = await readFile(join(dist, "index.html"), "utf8");' "$(fence $L/critical-css.md '// The shell the build wrote')"
restart
block css-after
osession "$LH" "$CSS"
block css-waterfall
osession '~/planner' 'node tools/waterfall.ts http://localhost:3000/courses/git --slow'
bg_stop ssr INT
