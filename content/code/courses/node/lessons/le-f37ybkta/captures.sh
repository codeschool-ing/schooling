#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of node, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l4.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l4.txt; done
#
# THE PUBLIC REGISTRY. Every install here asks registry.npmjs.org, so a count
# of packages or an advisory is what the registry held on the day of the run;
# the lesson says so. The versions asked for are exact.
#
# STAGED: package.json, src/code.js, server.js and test/code.test.js are taken
# out of the lesson's .md by lab/shown.py. server.js runs "in a second
# terminal" and is stopped afterwards.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L='~/server/links'
quiet '~/server' 'rm -rf links older audited strict && mkdir -p links/src links/test older audited strict'
shown an-application.md package.json $L/package.json
shown an-application.md src/code.js $L/src/code.js
shown installing-express.md server.js $L/server.js
shown the-test-runner.md test/code.test.js $L/test/code.test.js

block pkg-get
session $L 'npm pkg get name version type'
block code
session $L "node -e 'import(\"./src/code.js\").then((m) => console.log(m.makeCode(), m.ALPHABET.length))'"
block install
session $L 'npm install express@5.3.0'
block ls
session $L 'npm ls' 'npm ls --all | wc -l' 'du -sh node_modules'
block explain
session $L 'npm explain debug'
bg links $L 'node server.js'
wait_port 3000
block server-start
bg_show links
block curl
session $L 'curl -s http://127.0.0.1:3000/' 'curl -s http://127.0.0.1:3000/'
bg_stop links INT

block dev
session $L 'npm install --save-dev --save-exact prettier@3.9.10' 'npm pkg get dependencies devDependencies'
block omit
session $L 'npm ls --omit=dev'
block scripts
session $L 'npm run'
block format
session $L 'npm run format'
block hello
session $L "npm pkg set scripts.hello='echo hello from \$npm_lifecycle_event'" 'npm run hello' 'node --run hello' \
  'npm pkg delete scripts.hello'

block test
session $L 'npm test'
block test-fail
session $L "sed -i 's/ALPHABET = \"23456789/ALPHABET = \"123456789/' src/code.js" 'npm test; echo "exit code $?"' \
  "sed -i 's/ALPHABET = \"123456789/ALPHABET = \"23456789/' src/code.js"

block ci
session $L 'npm ci'
block ci-sync
session $L "npm pkg set dependencies.express='^4.21.0'" 'npm ci 2>&1 | head -6' "npm pkg set dependencies.express='^5.3.0'"
block ci-prod
session $L 'npm ci --omit=dev' 'npm run format'
quiet $L 'npm ci && echo engine-strict=true > .npmrc && echo node_modules/ > .gitignore'

block older
session '~/server/older' "echo '{ \"name\": \"older\", \"private\": true }' > package.json" 'npm install express@5.1.0' \
  'npm outdated; echo "exit code $?"'
block update
session '~/server/older' 'npm update' 'npm ls'

block audited
session '~/server/audited' "echo '{ \"name\": \"audited\", \"private\": true }' > package.json" 'npm install express@4.17.1'
block audit
session '~/server/audited' 'npm audit'
block audit-fix
session '~/server/audited' 'npm audit fix' 'npm ls express'
block override
session '~/server/audited' 'npm install --save-exact express@4.17.1' 'npm pkg set overrides.qs=6.16.1' 'npm install' \
  'npm ls qs' "npm audit | grep -E '^[a-z-]+  '"

block strict
session '~/server/strict' "echo '{ \"name\": \"strict\", \"private\": true, \"engines\": { \"node\": \">=24\" } }' > package.json" \
  'echo engine-strict=true > .npmrc' 'npm install express@5.3.0'
