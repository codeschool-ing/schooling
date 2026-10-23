#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l5.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l5.txt; done
#
# Every program is taken out of the lesson's .md by lab/shown.py. Each server
# runs "in a second terminal" (lab/lib.sh's bg) and is stopped with Ctrl-C's
# signal afterwards; where the lesson shows that terminal, bg_show prints it.
# A link's code is random, so the run picks it out of the reply to the POST
# and types it, as a person reading the reply would.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
N='~/server/native'
quiet '~/server' 'rm -rf native && mkdir native'
for f in listen.js:create-server echo.js:the-request respond.js:the-response routes.js:routing-by-hand \
         params.js:path-parameters body.js:reading-a-body fragile.js:errors-in-handlers sturdy.js:errors-in-handlers \
         slow.js:timeouts server.js:the-whole-server; do
  shown ${f#*:}.md ${f%%:*} $N/${f%%:*}
done
run_server() { bg $1 $N "node $1.js"; wait_port 3000; }

block package
session $N "echo '{ \"name\": \"native\", \"private\": true, \"type\": \"module\" }' > package.json"
block port-zero
bg listen $N 'node listen.js 0'
sleep 0.5; bg_stop listen INT; bg_show listen; printf '^C\n'

run_server echo
block echo
session $N "curl -s -H 'X-Request-Id: abc-123' 'http://127.0.0.1:3000/links/7ctxqn?visits=1&format=json'"
block curl-v
session $N "curl -sv http://127.0.0.1:3000/ 2>&1 | grep '^>'"
bg_stop echo INT

run_server respond
block respond
session $N 'curl -si http://127.0.0.1:3000/whole' 'curl -si http://127.0.0.1:3000/json' \
  'curl -si http://127.0.0.1:3000/pieces' 'curl -s http://127.0.0.1:3000/late'
bg_stop respond INT
block respond-server
bg_show respond; printf '^C\n'

run_server routes
block routes
session $N 'curl -s http://127.0.0.1:3000/links' 'curl -s -X POST http://127.0.0.1:3000/links' \
  'curl -si -X DELETE http://127.0.0.1:3000/links' 'curl -s http://127.0.0.1:3000/nothing' \
  "curl -s 'http://127.0.0.1:3000/health?verbose=1'"
bg_stop routes INT

run_server params
block params
session $N 'curl -s http://127.0.0.1:3000/links/7ctxqn' 'curl -s http://127.0.0.1:3000/links/caf%C3%A9' \
  'curl -s http://127.0.0.1:3000/links/a%2Fb' 'curl -s http://127.0.0.1:3000/links/%E0%A4%A'
bg_stop params INT

run_server body
block body
session $N "curl -s -H 'content-type: application/json' -d '{\"url\": \"https://example.com/\"}' http://127.0.0.1:3000/" \
  "curl -s -d 'url=https://example.com/' http://127.0.0.1:3000/" \
  "curl -s -H 'content-type: application/json' -d '{\"url\": ' http://127.0.0.1:3000/" \
  "head -c 2000 /dev/zero | tr '\\0' 'a' | curl -s -H 'content-type: application/json' -d @- http://127.0.0.1:3000/"
bg_stop body INT

run_server fragile
block fragile
session $N 'curl -s http://127.0.0.1:3000/ok; curl -s http://127.0.0.1:3000/%E0%A4%A; curl -s http://127.0.0.1:3000/ok; echo "curl exit code $?"'
sleep 0.3
block fragile-server
bg_show fragile
run_server sturdy
block sturdy
session $N 'curl -s http://127.0.0.1:3000/ok; curl -s http://127.0.0.1:3000/%E0%A4%A; curl -s http://127.0.0.1:3000/ok'
bg_stop sturdy INT
block sturdy-server
bg_show sturdy; printf '^C\n'

block timeouts
session $N "node -p 'const s = require(\"node:http\").createServer(); [s.headersTimeout, s.requestTimeout, s.keepAliveTimeout]'"
block slow
session $N 'node slow.js'

run_server server
block create
session $N "curl -si -H 'content-type: application/json' -d '{\"url\": \"https://nodejs.org/docs/latest-v22.x/api/\"}' http://127.0.0.1:3000/links"
CODE=$(bash "$LAB_SH" script 'curl -s http://127.0.0.1:3000/links' | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["code"])')
block follow
session $N "curl -si http://127.0.0.1:3000/$CODE | head -3" "curl -s http://127.0.0.1:3000/links/$CODE" \
  'curl -s http://127.0.0.1:3000/links/nope22' 'curl -si -X PUT http://127.0.0.1:3000/links | head -1' \
  "curl -s -H 'content-type: application/json' -d '{\"url\": \"javascript:alert(1)\"}' http://127.0.0.1:3000/links" \
  "curl -si -X DELETE http://127.0.0.1:3000/links/$CODE | head -1" 'curl -s http://127.0.0.1:3000/links'
bg_stop server INT
block server-log
bg_show server; printf '^C\n'
