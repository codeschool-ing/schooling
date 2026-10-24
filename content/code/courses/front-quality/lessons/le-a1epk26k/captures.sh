#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 5 > out.txt
#
# It starts from the tag lesson-4 and leaves lesson-5. server/api.mjs,
# server/jwt.mjs, server/try-jwt.mjs and vite.config.ts are taken from the
# lesson's own listings by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "start" is the log of `npm run api`, started in the background by
#     serve(); the dev server is started the same way, and every curl
#     ran meanwhile, as from a second terminal.
#   - The session id and the Date header differ on every run: the id is 32
#     random bytes, as it must be.
#   - Nothing here talks to an identity provider: oauth.md says why.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 4
rm -f /home/ana/cookies.txt

put the-server.md server/api.mjs $P/server/api.mjs
block script
run $P 'npm pkg set scripts.api="node server/api.mjs"'
run $P 'npm pkg get scripts.api'
put the-server.md vite.config.ts $P/vite.config.ts

serve 3000 $P 'npm run api'
block start
printf 'ana@dev:~/planner$ npm run api\n'
cat /var/tmp/front-quality-server-3000.log
serve 5173 $P 'npm run dev'

block wrong
run $P "curl -s -i -X POST -H 'content-type: application/json' -d '{\"name\":\"ana\",\"password\":\"hunter2\"}' http://localhost:5173/api/login"
block login
run $P "curl -s -i -c ~/cookies.txt -X POST -H 'content-type: application/json' -d '{\"name\":\"ana\",\"password\":\"correct horse battery staple\"}' http://localhost:5173/api/login"
block plan
run $P 'curl -s -b ~/cookies.txt http://localhost:5173/api/plan | head -c 150; echo'
run $P 'curl -s -i http://localhost:5173/api/plan'
unserve 5173
unserve 3000

put tokens.md server/jwt.mjs $P/server/jwt.mjs
put tokens.md server/try-jwt.mjs $P/server/try-jwt.mjs
block jwt
run $P 'node server/try-jwt.mjs'

block pkce
run $P "node -e 'const { createHash } = require(\"node:crypto\"); console.log(createHash(\"sha256\").update(\"dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk\").digest(\"base64url\"))'"
block verifier
run $P "node -e 'console.log(require(\"node:crypto\").randomBytes(32).toString(\"base64url\").length)'"

block commit
export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "A server with one account, a session cookie, and a JWT by hand"'
leave 5
