#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l15.txt
#   F="python3 ../../lab/fill.py"
#   $F adapter-node.md /tmp/l15.txt --blocks install,build,web,web-title,fail-403
#   $F csrf.md /tmp/l15.txt --blocks origin-build,origin-ok,origin-evil
#   $F ssr-false.md /tmp/l15.txt --blocks ssr-body,ssr-look,ssr-nojs
#   $F csr-false.md /tmp/l15.txt --blocks csr-count,csr-back
#   $F prerender.md /tmp/l15.txt --blocks pre-build,pre-find,pre-fail,pre-rm
#   $F choosing.md /tmp/l15.txt --blocks static-install,static-build,static-uninstall
#
# It starts from the project as lesson 14 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; the builds the lesson
# asks for without showing ("build, restart the server"), run here quietly; and,
# at the end, the data file put back as Git has it, so that the session these
# transcripts added does not follow the project into lesson 16.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 14

bg_stop dev
build() { quiet '~/planner' 'ORIGIN=http://localhost:3000 npm run build'; }
restart_web() { bg_stop web; bg web '~/planner' 'node build'; wait_port 3000; sleep 0.5; }
A="src/routes/(info)/about/+page.js"

block install
session '~/planner' 'npm install --save-dev @sveltejs/adapter-node@6.0.0' 'npm uninstall @sveltejs/adapter-auto'
shown adapter-node.md vite.config.js '~/planner/vite.config.js'
block build
session '~/planner' 'npm run build 2>&1 | tail -5'
restart_web
block web
bg_show web
block web-title
session '~/planner' "curl -s http://localhost:3000/ | grep -o '<title>.*</title>'"
block fail-403
session '~/planner' "look http://localhost:3000/courses/guitar --fill 'Date=2026-10-22' --click 'Add session'"

bg_stop web
shown csrf.md vite.config.js '~/planner/vite.config.js'
block origin-build
session '~/planner' 'ORIGIN=http://localhost:3000 npm run build > /dev/null 2>&1; echo $?'
restart_web
block origin-ok
session '~/planner' "look http://localhost:3000/courses/guitar --fill 'Date=2026-10-22' --click 'Add session' --wait 500 | head -6"
block origin-evil
session '~/planner' "curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -H 'Origin: https://elsewhere.example' -d 'date=2026-10-23&minutes=30' 'http://localhost:3000/courses/guitar?/add'" \
  "curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-10-23&minutes=30' 'http://localhost:3000/courses/guitar?/add'"

shown ssr-false.md "$A" "~/planner/$A"
build; restart_web
block ssr-body
session '~/planner' "curl -s http://localhost:3000/about | sed -n '/<body/,/<\/body>/p'"
block ssr-look
session '~/planner' 'look http://localhost:3000/about'
block ssr-nojs
session '~/planner' 'look http://localhost:3000/about --no-js'

shown csr-false.md "$A" "~/planner/$A"
build; restart_web
block csr-count
session '~/planner' "curl -s http://localhost:3000/about | grep -c '<script'" "curl -s http://localhost:3000/ | grep -c '<script'"
block csr-back
session '~/planner' "look http://localhost:3000/about --click 'Back to the planner' | head -4"

bg_stop web
shown prerender.md "$A" "~/planner/$A"
block pre-build
session '~/planner' 'ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A1 Prerendering'
block pre-find
session '~/planner' "find build -name '*.html'"
shown prerender.md src/routes/+layout.js '~/planner/src/routes/+layout.js'
block pre-fail
session '~/planner' "ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A2 'SvelteKit error'"
block pre-rm
session '~/planner' 'rm src/routes/+layout.js'

block static-install
session '~/planner' 'npm install --save-dev @sveltejs/adapter-static@4.0.0'
shown choosing.md vite.config.js '~/planner/vite.config.js'
block static-build
session '~/planner' "npm run build 2>&1 | grep -A3 'adapter-static:'"
shown csrf.md vite.config.js '~/planner/vite.config.js'
block static-uninstall
session '~/planner' 'npm uninstall @sveltejs/adapter-static'

build
quiet '~/planner' 'git checkout data/planner.json; rm -f data/planner.json.new'
done_lesson 15 "adapter-node, the origin for CSRF, and About prerendered with no JavaScript"
