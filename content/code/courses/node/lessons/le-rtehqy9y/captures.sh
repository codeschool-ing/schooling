#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l7.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l7.txt; done
#
# Starts from the links project as lesson 6 left it (its captures build it),
# with ~/.curlrc printing a newline after every reply. Every program is taken
# out of the lesson's .md by lab/shown.py; src/links.js and src/app.js replace
# lesson 6's. Servers run "in a second terminal" and are stopped afterwards.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L='~/server/links'
quiet $L 'rm -f jar.txt'
for f in param.js:params query.js:query limit.js:query body.js:body headers.js:request-headers \
         redirects.js:response-helpers cookies.js:cookies ip.js:proxies-and-headers; do
  shown ${f#*:}.md demo/${f%%:*} $L/demo/${f%%:*}
done
shown validation.md src/links.js $L/src/links.js
shown proxies-and-headers.md src/app.js $L/src/app.js
srv() { bg $1 $L "$2"; wait_port 3000; }
stop() { bg_stop $1 INT; }
J="-H 'content-type: application/json'"

srv param 'node demo/param.js'
block param
session $L 'curl -s http://127.0.0.1:3000/links/7ctxqn' 'curl -s http://127.0.0.1:3000/links/7ctxq1' \
  'curl -s http://127.0.0.1:3000/links/7ctxqnabc' 'curl -s -X DELETE http://127.0.0.1:3000/links/a%20b'
stop param

srv query 'node demo/query.js'
block query
session $L "curl -sg 'http://127.0.0.1:3000/q?limit=10&tag=a&tag=b&empty=&user[admin]=true'"
stop query
srv limit 'node demo/limit.js'
block limit
session $L "curl -s 'http://127.0.0.1:3000/links'" "curl -s 'http://127.0.0.1:3000/links?limit=5'" \
  "curl -s 'http://127.0.0.1:3000/links?limit=2.5'" "curl -s 'http://127.0.0.1:3000/links?limit=abc'" \
  "curl -s 'http://127.0.0.1:3000/links?limit=1&limit=2'" "curl -s 'http://127.0.0.1:3000/links?limit=10000000'"
stop limit

srv body 'node demo/body.js'
block body
session $L "curl -s $J -d '\"https://example.com/\"' http://127.0.0.1:3000/links" \
  "curl -s $J -d '{\"url\": \"https://example.com/\"}' http://127.0.0.1:3000/links" \
  "curl -s -X POST http://127.0.0.1:3000/links" \
  "curl -s $J -d '{\"url\": \"https://example.com/\", }' http://127.0.0.1:3000/links"
stop body

srv server 'node server.js'
block validate
session $L "curl -s $J -d '{\"ur1\": \"https://example.com/\"}' http://127.0.0.1:3000/links" \
  "curl -s $J -d '{\"url\": 42, \"note\": \"hi\"}' http://127.0.0.1:3000/links" \
  "curl -s $J -d '[\"https://example.com/\"]' http://127.0.0.1:3000/links" \
  "curl -s $J -d '{\"url\": \"ftp://example.com/file\"}' http://127.0.0.1:3000/links" \
  "curl -s -o /dev/null -w '%{http_code}\n' $J -d '{\"url\": \"https://example.com/\"}' http://127.0.0.1:3000/links"
CODE=$(bash "$LAB_SH" script "curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links" | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["code"])')
TAG=$(bash "$LAB_SH" script "curl -si http://127.0.0.1:3000/links/$CODE" | grep -i '^etag' | cut -d' ' -f2 | tr -d '\r')
block conditional
session $L "curl -si http://127.0.0.1:3000/links/$CODE | grep -i etag" \
  "curl -si -H 'If-None-Match: $TAG' http://127.0.0.1:3000/links/$CODE | head -1" \
  "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/$CODE" \
  "curl -si -H 'If-None-Match: $TAG' http://127.0.0.1:3000/links/$CODE | grep -iE '^HTTP|^etag'"
block no-store
session $L "curl -si -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links | grep -iE '^(cache-control|etag)'"
block nosniff
session $L "curl -si http://127.0.0.1:3000/links/$CODE | head -6"
stop server
block server-log
bg_show server; printf '^C\n'

srv headers 'node demo/headers.js'
block headers
session $L "curl -s -H 'content-type: text/plain' -d 'hello' http://127.0.0.1:3000/echo" \
  "curl -s $J -d '{}' http://127.0.0.1:3000/echo" \
  'curl -s http://127.0.0.1:3000/links/7ctxqn' "curl -s -H 'accept: text/plain' http://127.0.0.1:3000/links/7ctxqn" \
  "curl -s -H 'accept: image/png' http://127.0.0.1:3000/links/7ctxqn"
stop headers

srv redirects 'node demo/redirects.js'
block redirects
session $L 'curl -sL -d x=1 http://127.0.0.1:3000/r302' 'curl -sL -d x=1 http://127.0.0.1:3000/r307' \
  'curl -sL -d x=1 http://127.0.0.1:3000/r301' 'curl -sL -d x=1 http://127.0.0.1:3000/r308' \
  "curl -si http://127.0.0.1:3000/r302 | grep -iE '^HTTP|^location'"
stop redirects

srv cookies 'node demo/cookies.js'
block cookies
session $L "curl -si -c jar.txt http://127.0.0.1:3000/ | grep -iE '^set-cookie|visit'" \
  'curl -s -b jar.txt -c jar.txt http://127.0.0.1:3000/' 'curl -s -b jar.txt -c jar.txt http://127.0.0.1:3000/'
stop cookies

srv ip 'node demo/ip.js'
block ip-none
session $L "curl -s -H 'X-Forwarded-For: 203.0.113.9' http://127.0.0.1:3000/ip"
stop ip
srv ip2 'node demo/ip.js loopback'
block ip-loopback
session $L "curl -s -H 'X-Forwarded-For: 203.0.113.9' http://127.0.0.1:3000/ip"
stop ip2

block test
session $L 'npm test 2>&1 | grep -E "^(✔|✖|ℹ (tests|pass|fail))"'
