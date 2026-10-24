#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 7 > out.txt
#
# It starts from the tag lesson-6 and leaves lesson-7. server/look.mjs and
# the tests are taken from the lesson's own listings by lab/extract.py; the
# wildcard experiment and the fix are the changes the lesson shows, applied
# by exact replacements, and `git diff` prints them.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The API (npm run api) and the dev server are started in the background
#     by serve(), as from two other terminals, and restarted after each change
#     to server/api.mjs, as a person would press Ctrl+C and start it again.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 6

put the-error.md server/look.mjs $P/server/look.mjs
restart() { unserve 3000; serve 3000 $P 'npm run api'; }
serve 3000 $P 'npm run api'
serve 5173 $P 'npm run dev'
GET_PLAN='fetch("http://localhost:3000/api/plan").then((r) => r.status, (e) => String(e))'
LOGIN='fetch("http://localhost:3000/api/login", { method: "POST", headers: { "content-type": "application/json" }, body: "{}" }).then((r) => r.status, (e) => String(e))'
WITH_COOKIES='fetch("http://localhost:3000/api/plan", { credentials: "include" }).then((r) => r.status, (e) => String(e))'
BOTH='(async () => { const login = await fetch("http://localhost:3000/api/login", { method: "POST", credentials: "include", headers: { "content-type": "application/json" }, body: JSON.stringify({ name: "ana", password: "correct horse battery staple" }) }); const plan = await fetch("http://localhost:3000/api/plan", { credentials: "include" }); return `sign-in ${login.status}, plan ${plan.status}`; })()'

block blocked
run $P "node server/look.mjs http://localhost:5173/ '$GET_PLAN'"
block curl
run $P 'curl -s -i http://localhost:3000/api/plan'
block preflight
run $P "node server/look.mjs http://localhost:5173/ '$LOGIN'"
block options
run $P "curl -s -i -X OPTIONS -H 'Origin: http://localhost:5173' -H 'Access-Control-Request-Method: POST' -H 'Access-Control-Request-Headers: content-type' http://localhost:3000/api/login"

fix server/api.mjs '    const path = new URL(req.url, "http://localhost").pathname;' '    const path = new URL(req.url, "http://localhost").pathname;
    res.setHeader("access-control-allow-origin", "*");'
block wildcard-diff
run $P 'git diff server/api.mjs'
restart
block wildcard-get
run $P "node server/look.mjs http://localhost:5173/ '$GET_PLAN'"
block wildcard-credentials
run $P "node server/look.mjs http://localhost:5173/ '$WITH_COOKIES'"
block wildcard-undo
run $P 'git checkout server/api.mjs'

python3 "$FQ_LAB/extract.py" "$LESSON/the-fix.md" "server/api.test.mjs, below what is there" | sed 1d | sed '1s/^/\n/' >> $P/server/api.test.mjs
block red
run $P 'npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError| Test Files|      Tests)"'

fix server/api.mjs 'export function createApi() {' 'const allowed = new Set(["http://localhost:5173"]);

function corsHeaders(req) {
  if (!allowed.has(req.headers.origin)) return {};
  return { "access-control-allow-origin": req.headers.origin, "access-control-allow-credentials": "true", vary: "Origin" };
}

export function createApi() {'
fix server/api.mjs '    const user = login && Date.now() < login.until ? login.name : undefined;
' '    const user = login && Date.now() < login.until ? login.name : undefined;
    for (const [name, value] of Object.entries(corsHeaders(req))) res.setHeader(name, value);

    if (req.method === "OPTIONS") {
      res.writeHead(204, {
        "access-control-allow-methods": "GET, POST",
        "access-control-allow-headers": "content-type",
        "access-control-max-age": "600",
      });
      return res.end();
    }
'
block diff
run $P 'git diff server/api.mjs'
block green
run $P 'npx vitest run server/api.test.mjs'
restart
block works
run $P "node server/look.mjs http://localhost:5173/ '$BOTH'"
unserve 5173
unserve 3000
block commit
export GIT_AUTHOR_DATE='2026-10-21 14:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 14:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "Allow the planner'"'"'s own origin, and no other, to read the API"'
leave 7
