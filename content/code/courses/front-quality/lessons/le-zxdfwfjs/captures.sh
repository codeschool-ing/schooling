#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of front-quality, as a script that
# produces them. lab/fill.py pastes each block into the fence that holds it.
#
#   bash ../../lab.sh capture 8 > out.txt
#
# It starts from the tag lesson-7 and leaves lesson-8. The test, the witness
# and vite.config.ts are taken from the lesson's own listings by
# lab/extract.py; the experiments are exact replacements, shown by `git diff`
# and undone by `git checkout`, which is shown too.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "hsts" reaches nodejs.org through the recording machine's proxy, which
#     passes the site's response headers on unchanged.
#   - The preview and dev servers are started in the background by serve(),
#     as from other terminals, and restarted after each change to
#     vite.config.ts, which both read only when they start.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
resume 7

block hsts
run $P 'curl -s -o /dev/null -D - https://nodejs.org/ | grep -i strict-transport-security'

block build
run $P 'npm run build'
serve 4173 $P 'npx vite preview --port 4173 --strictPort'
block bare
run $P 'curl -s -I http://localhost:4173/'
unserve 4173

fix playwright.config.ts '    { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
  ],' '    { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
    {
      command: "npm run build && npx vite preview --port 4173 --strictPort",
      url: "http://localhost:4173",
      reuseExistingServer: true,
    },
  ],'
block config-diff
run $P 'git diff playwright.config.ts'
put a-test-first.md e2e/headers.spec.ts $P/e2e/headers.spec.ts
block red
run $P 'npx playwright test e2e/headers.spec.ts --reporter=list 2>&1 | grep -E "^  (✓|✘)|Error:|Received|passed|failed"'

put the-policy.md vite.config.ts $P/vite.config.ts
block green
run $P 'npx playwright test e2e/headers.spec.ts --reporter=list'
serve 4173 $P 'npx vite preview --port 4173 --strictPort'
block headers
run $P 'curl -s -I http://localhost:4173/'
block commit
export GIT_AUTHOR_DATE='2026-10-22 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-22 09:00:00 -0300'
run $P 'git add -A'
run $P 'git commit -q -m "Serve the build with a Content Security Policy and four other headers"'

put the-witness.md server/witness.js $P/server/witness.js
serve 5173 $P 'npm run dev'
block dev
run $P 'node server/look.mjs http://localhost:5173/ "$(cat server/witness.js)"'
block built
run $P 'node server/look.mjs http://localhost:4173/ "$(cat server/witness.js)"'

fix vite.config.ts '  "Content-Security-Policy": [' '  "Content-Security-Policy-Report-Only": ['
block ro-diff
run $P 'git diff vite.config.ts'
unserve 4173; serve 4173 $P 'npx vite preview --port 4173 --strictPort'
block ro-look
run $P 'node server/look.mjs http://localhost:4173/ "$(cat server/witness.js)"'
block ro-undo
run $P 'git checkout vite.config.ts'

fix vite.config.ts '    proxy: { "/api": "http://127.0.0.1:3000" },
  },' '    proxy: { "/api": "http://127.0.0.1:3000" },
    headers: securityHeaders,
  },'
block dev-diff
run $P 'git diff vite.config.ts'
unserve 5173; serve 5173 $P 'npm run dev'
block dev-look
run $P 'node server/look.mjs http://localhost:5173/ "getComputedStyle(document.body).maxWidth"'
block dev-undo
run $P 'git checkout vite.config.ts'
unserve 5173; unserve 4173
export GIT_AUTHOR_DATE='2026-10-22 09:30:00 -0300' GIT_COMMITTER_DATE='2026-10-22 09:30:00 -0300'
commit '2026-10-22 09:30' 'The inline-script witness'
leave 8
