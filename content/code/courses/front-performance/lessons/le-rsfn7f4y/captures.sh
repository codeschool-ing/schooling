#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l11.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l11.txt; done
#
# It first puts ~/planner back as lesson 10 left it, from the files of lessons 1
# and 4 to 10, so it can be run again. Files the lesson shows whole are taken out
# of it by lab/shown.py; the changes it shows as a fragment are made by
# lab/edit.sh with the fragment taken out of the lesson.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
. ../../lab/edit.sh
L=$PWD; L9=$L/../le-t1e4sdqx; L10=$L/../le-aw36jwxk
P=/home/ana/planner
L1=$L/../le-3s959ek5; L2=$L/../le-7gh59h40; L4=$L/../le-3bzm1e2v; L5=$L/../le-fa611g27; L6=$L/../le-2ek1kvv8; L7=$L/../le-vzsqtc54; L8=$L/../le-ay3mpygn
for n in ssr str nx nu sv ng pv edge; do bg_stop $n; done
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
# Lesson 8's own changes.
shown $L8/a-feature-one-page-uses.md src/chart.ts '~/planner/src/chart.ts'
edit $P/src/chart.ts replace 'import { Chart } from "chart.js/auto";' "$(fence $L8/importing-less.md '// Only the pieces a bar chart uses')"
edit $P/src/view.ts before '// The page an address names' "$(fence $L8/a-feature-one-page-uses.md '// The minutes of every week')"
edit $P/src/view.ts replace-to '// The page an address names|}' "$(fence $L8/a-feature-one-page-uses.md '// The page an address names')"
edit $P/src/view.ts replace '<h2>Weeks</h2>' "$(fence $L8/a-feature-one-page-uses.md '<h2>Weeks</h2>')"
edit $P/src/view.ts replace-to 'export function mount(|  const draw = ' "$(fence $L8/a-feature-one-page-uses.md 'export function mount(')"
edit $P/src/view.ts replace-to '  if (!root.firstElementChild) {|  document.documentElement.dataset.hydrated' "$(fence $L8/a-feature-one-page-uses.md 'if (!root.firstElementChild) {')"
edit $P/src/main.ts replace 'mount(document.querySelector' "$(fence $L8/import-on-demand.md 'mount(document.querySelector')"
edit $P/src/main.ts after '});' "$(fence $L8/when-to-fetch-it.md '// A pointer resting on the link')"
quiet '~/planner' 'npm install --save-exact chart.js@4.5.1; rm -f tools/revisit.ts tools/edge.ts tools/heads.ts'
# Lesson 9's own changes.
shown $L9/a-second-visit.md tools/revisit.ts '~/planner/tools/revisit.ts'
edit $P/server.ts after 'import { gzipSync } from "node:zlib";' "$(fence $L9/two-rules.md 'import { createHash }')"
edit $P/server.ts replace-to '// Every answer goes through here.|};' "$(fence $L9/two-rules.md '// Every answer goes through here.')"
edit $P/server.ts replace '      send(req, res, types[extname(pathname)]' "$(fence $L9/two-rules.md 'send(req, res, types[extname(pathname)]')"
edit $P/server.ts replace '  send(req, res, "text/html; charset=utf-8", html);' "$(fence $L9/stale-at-the-edge.md 'send(req, res, "text/html; charset=utf-8", html, "max-age=0')"
# Lesson 10's own changes.
shown $L10/the-planners-worker.md public/sw.js '~/planner/public/sw.js'
shown $L10/the-planners-worker.md public/offline.html '~/planner/public/offline.html'
edit $P/src/main.ts append - "$(fence $L10/the-planners-worker.md '// The service worker, registered')"
edit $P/server.ts replace-to 'const types|};' "$(fence $L10/the-planners-worker.md 'const types')"
quiet '~/planner' 'rm -rf public/manifest.webmanifest public/icons tools/installable.ts tools/icons.ts tools/notify.ts tools/push.ts'

# The manifest.
shown $L/the-manifest.md public/manifest.webmanifest '~/planner/public/manifest.webmanifest'
edit $P/index.html before '    <title>Study planner</title>' "$(fence $L/the-manifest.md '<link rel="manifest"')"
edit $P/server.ts replace '  ".png": "image/png", ".woff2": "font/woff2",' "$(fence $L/the-manifest.md '".png": "image/png"')"
shown $L/the-manifest.md tools/installable.ts '~/planner/tools/installable.ts'
restart
block no-icons
osession '~/planner' 'node tools/installable.ts http://localhost:3000/'

# Icons.
shown $L/icons.md tools/icons.ts '~/planner/tools/icons.ts'
block icons
osession '~/planner' 'node tools/icons.ts'
restart
block installable
osession '~/planner' 'node tools/installable.ts http://localhost:3000/'

# The install button.
edit $P/index.html before '    <main id="app"></main>' "$(fence $L/an-install-button.md '<button id="install"')"
edit $P/src/style.css append - "$(fence $L/an-install-button.md '.install {')"
edit $P/src/main.ts append - "$(fence $L/an-install-button.md '// Chromium offers to install')"
restart
block button
osession '~/planner' 'node tools/installable.ts http://localhost:3000/'

# Notifications.
shown $L/notifications.md tools/notify.ts '~/planner/tools/notify.ts'
block notify
osession '~/planner' 'node tools/notify.ts http://localhost:3000/' 'node tools/notify.ts http://localhost:3000/ --allow'

# Push.
edit $P/public/sw.js append - "$(fence $L/push.md '// A push message from')"
edit $P/public/sw.js replace 'const CACHE = "planner-v1";' "$(fence $L/push.md 'const CACHE = "planner-v2";')"
shown $L/push.md tools/push.ts '~/planner/tools/push.ts'
restart
block push
osession '~/planner' "node tools/push.ts http://localhost:3000/ '{\"title\": \"Study planner\", \"body\": \"Git, 30 minutes, today\"}'"
bg_stop ssr INT
