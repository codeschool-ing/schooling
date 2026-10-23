#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l6.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l6.txt; done
#
# Starts from the links project as lesson 4 left it (its captures build it):
# package.json, src/code.js, test/code.test.js and Express 5.3.0 installed.
# Every program is taken out of the lesson's .md by lab/shown.py; servers run
# "in a second terminal" and are stopped afterwards.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L='~/server/links'
quiet $L 'rm -rf demo public ~/.curlrc && mkdir demo && npm ci --silent'
for f in first.js:first-app routes.js:routes patterns.js:path-syntax old-pattern.js:path-syntax chain.js:middleware \
         json.js:built-in-middleware static.js:built-in-middleware admin.js:router-middleware errors.js:error-handlers \
         handler.js:error-handlers notfound.js:not-found; do
  shown ${f#*:}.md demo/${f%%:*} $L/demo/${f%%:*}
done
for f in src/store.js src/admin.js src/links.js src/app.js server.js test/links.test.js; do shown the-links-app.md $f $L/$f; done
srv() { bg $1 $L "$2"; wait_port 3000; }
stop() { bg_stop $1 INT; }

block curlrc
session $L "echo '-w \"\\n\"' >> ~/.curlrc" 'cat ~/.curlrc'
srv first 'node demo/first.js'
block first
session $L 'curl -si http://127.0.0.1:3000/' "curl -s 'http://127.0.0.1:3000/links/7ctxqn?visits=1'"
stop first

srv routes 'node demo/routes.js'
block routes
session $L 'curl -s http://127.0.0.1:3000/links' 'curl -s -X POST http://127.0.0.1:3000/links' \
  'curl -s http://127.0.0.1:3000/links/' 'curl -s http://127.0.0.1:3000/ADMIN/stats' \
  'curl -s http://127.0.0.1:3000/links/new' 'curl -s http://127.0.0.1:3000/links/7ctxqn'
stop routes

srv patterns 'node demo/patterns.js'
block patterns
session $L 'curl -s http://127.0.0.1:3000/links/7ctxqn' 'curl -s http://127.0.0.1:3000/stats' \
  'curl -s http://127.0.0.1:3000/stats/week' 'curl -s http://127.0.0.1:3000/files/2026/october/report.txt'
stop patterns
block old-pattern
session $L 'node demo/old-pattern.js 2>&1 | grep TypeError'

srv chain 'node demo/chain.js'
block chain
session $L 'curl -s http://127.0.0.1:3000/health; curl -s http://127.0.0.1:3000/links' \
  'curl -si http://127.0.0.1:3000/links | grep -i x-request-id' \
  'curl -s -m 2 http://127.0.0.1:3000/forgot; echo "curl exit code $?"'
stop chain
block chain-server
bg_show chain; printf '^C\n'

srv json 'node demo/json.js'
block json
session $L "curl -s -H 'content-type: application/json' -d '{\"url\": \"https://example.com/\"}' http://127.0.0.1:3000/links" \
  "curl -s -d 'url=https://example.com/' http://127.0.0.1:3000/links"
stop json

block static
session $L "mkdir -p public && echo '<h1>links</h1>' > public/index.html"
srv static 'node demo/static.js'
session $L 'curl -si http://127.0.0.1:3000/' 'curl -s -o /dev/null -w "%{http_code}\n" --path-as-is http://127.0.0.1:3000/../package.json'
stop static

srv admin 'node demo/admin.js'
block admin
session $L 'curl -s http://127.0.0.1:3000/links' "curl -s -H 'x-admin-key: guess' http://127.0.0.1:3000/links" \
  "curl -s -H 'X-Admin-Key: change-me-in-lesson-9' http://127.0.0.1:3000/links" \
  'curl -s -X POST http://127.0.0.1:3000/links' 'curl -s http://127.0.0.1:3000/admin/stats'
stop admin

srv errors 'node demo/errors.js'
block errors
session $L "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/sync" \
  "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/async" \
  "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/next"
block default-dev
session $L 'curl -s http://127.0.0.1:3000/sync | head -8'
stop errors
bg errorsp $L 'NODE_ENV=production node demo/errors.js'; wait_port 3000
block default-prod
session $L 'curl -s http://127.0.0.1:3000/sync'
stop errorsp

srv handler 'node demo/handler.js'
block handler
session $L 'curl -s http://127.0.0.1:3000/broken' \
  "curl -s -H 'content-type: application/json' -d '{\"url\": ' http://127.0.0.1:3000/links" \
  "head -c 2000 /dev/zero | tr '\\0' 'a' | curl -s -H 'content-type: application/json' -d @- http://127.0.0.1:3000/links"
stop handler
block handler-server
bg_show handler; printf '^C\n'

srv notfound 'node demo/notfound.js'
block notfound
session $L 'curl -s http://127.0.0.1:3000/nothing' 'curl -si -X DELETE http://127.0.0.1:3000/links | grep -iE "^HTTP|^allow|error"'
stop notfound

srv server 'node server.js'
block create
session $L "curl -si -H 'content-type: application/json' -d '{\"url\": \"https://expressjs.com/\"}' http://127.0.0.1:3000/links"
CODE=$(bash "$LAB_SH" script "curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["code"])')
block follow
session $L "curl -si http://127.0.0.1:3000/$CODE | head -3" "curl -s http://127.0.0.1:3000/links/$CODE" \
  'curl -s http://127.0.0.1:3000/links' "curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links" \
  "curl -s -X DELETE -H 'x-admin-key: change-me-in-lesson-9' -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/links/$CODE" \
  'curl -s http://127.0.0.1:3000/nothing/here'
stop server
block server-log
bg_show server; printf '^C\n'

block test
session $L 'npm test'
