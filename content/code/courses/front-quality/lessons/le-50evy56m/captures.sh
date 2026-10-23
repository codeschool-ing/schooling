#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 6 > out.txt
#
# It starts from the tag lesson-5 and leaves lesson-6. The test files are
# taken from the lesson's own listings by lab/extract.py; the change to
# playwright.config.ts and the three changes to server/api.mjs are the ones
# the lesson shows, applied by exact replacements, and `git diff` prints them.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 5

fix playwright.config.ts '  webServer: {
    command: "npm run dev",
    url: "http://localhost:5173",
    reuseExistingServer: true,
  },' '  webServer: [
    { command: "npm run api", url: "http://127.0.0.1:3000/api/plan", reuseExistingServer: true },
    { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
  ],'
block config-diff
run $P 'git diff playwright.config.ts'

put what-a-script-sees.md e2e/storage.spec.ts $P/e2e/storage.spec.ts
put what-a-script-sees.md e2e/local-storage.spec.ts $P/e2e/local-storage.spec.ts
block storage
run $P 'npx playwright test e2e/storage.spec.ts e2e/local-storage.spec.ts --reporter=list'
block rm-local
run $P 'rm e2e/local-storage.spec.ts'

put three-tests.md server/api.test.mjs $P/server/api.test.mjs
block red
run $P 'npx vitest run server/api.test.mjs 2>&1 | grep -E "^( FAIL|AssertionError|Error:|- Expected|\+ Received|- |\+ | Test Files|      Tests)"'

fix server/api.mjs '    const user = logins.get(cookie(req, "sid"));' '    const login = logins.get(cookie(req, "__Host-sid"));
    const user = login && Date.now() < login.until ? login.name : undefined;'
fix server/api.mjs '      logins.set(sid, name);
      return send(res, 200, { name }, { "set-cookie": `sid=${sid}; HttpOnly; SameSite=Lax; Path=/` });' '      logins.set(sid, { name, until: Date.now() + 8 * 60 * 60 * 1000 });
      return send(res, 200, { name }, {
        "set-cookie": `__Host-sid=${sid}; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=28800`,
      });'
fix server/api.mjs '      return send(res, 200, {}, { "set-cookie": "sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0" });' '      logins.delete(cookie(req, "__Host-sid"));
      return send(res, 200, {}, { "set-cookie": "__Host-sid=; HttpOnly; Secure; SameSite=Lax; Path=/; Max-Age=0" });'
block diff
run $P 'git diff server/api.mjs'
block green
run $P 'npx vitest run server/api.test.mjs'
block all
run $P 'npm run check 2>&1 | grep -E "Tests |[0-9] (passed|failed)"'
block commit
export GIT_AUTHOR_DATE='2026-10-21 11:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 11:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "End a login on sign-out and after eight hours, and mark its cookie __Host-"'
leave 6
