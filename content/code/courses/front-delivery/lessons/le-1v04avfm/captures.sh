#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of front-delivery, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py and not
# committed.
#
#   sudo bash captures.sh > /tmp/l2.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l2.txt; done
#
# It runs on the planner as lesson 1 left it, the commit tagged lesson-1, and
# tags what it leaves lesson-2. STAGED: the token is a made-up string that opens nothing anywhere;
# support-service.mjs stands in for a third-party service and says so.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bash ../../lab.sh down >/dev/null 2>&1
quiet '~/planner' 'git reset -q --hard lesson-1 && git clean -fdq'

# Baked in.
shown baked-in.md src/env.ts '~/planner/src/env.ts'
block edit
session '~/planner' "sed -i '2i import { title } from \"./env\";' src/view.ts" \
  "sed -i 's/el(\"h1\", \"Study planner\")/el(\"h1\", title)/' src/view.ts" 'git diff'
block baked
session '~/planner' 'npm run build > /dev/null' "grep -o 'Study planner[^\`]*' dist/assets/*.js" \
  'grep -c VITE_TITLE dist/assets/*.js' \
  "VITE_TITLE='Study planner (staging)' npm run build > /dev/null" \
  "grep -o 'Study planner[^\`]*' dist/assets/*.js"
block baked-commit
session '~/planner' 'git add src/env.ts src/view.ts' 'git commit -qm "Take the title from VITE_TITLE"'

# The files.
block staging
session '~/planner' "echo 'VITE_TITLE=Study planner (staging)' > .env.staging" \
  'npm run build > /dev/null' "grep -o 'Study planner[^\`]*' dist/assets/*.js" \
  'npm run build -- --mode staging > /dev/null' "grep -o 'Study planner[^\`]*' dist/assets/*.js"
block wins
session '~/planner' "echo 'VITE_TITLE=Study planner (Ana)' > .env.staging.local" \
  'npm run build -- --mode staging > /dev/null' "grep -o 'Study planner[^\`]*' dist/assets/*.js" \
  "VITE_TITLE='Study planner (shell)' npm run build -- --mode staging > /dev/null" \
  "grep -o 'Study planner[^\`]*' dist/assets/*.js"
block status
session '~/planner' 'git status --short'
block staging-commit
session '~/planner' 'rm .env.staging.local' 'git add .env.staging' 'git commit -qm "A staging mode"'
bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
block devlocal
session '~/planner' "echo 'VITE_TITLE=Study planner (dev)' > .env.development.local"
sleep 3
block devlog
bg_show dev
bg_stop dev INT
quiet '~/planner' 'rm -f .env.development.local'

# The prefix.
block prefix
session '~/planner' "echo 'SUPPORT_TOKEN=tok-demo-not-a-real-secret' > .env.local" \
  "echo 'console.log(\"token:\", import.meta.env.SUPPORT_TOKEN);' >> src/main.ts" \
  'npm run build > /dev/null' "grep -o 'token:[^)]*' dist/assets/*.js"
block envprefix
session '~/planner' "echo 'export default { envPrefix: \"\" };' > vite.config.ts" 'npx vite build 2>&1 | head -2'
block rmconfig
session '~/planner' 'rm vite.config.ts'

# Nothing shipped is secret.
block exposed
session '~/planner' "sed -i 's/SUPPORT_TOKEN/VITE_SUPPORT_TOKEN/' .env.local src/main.ts" \
  'npm run build > /dev/null' "grep -o 'token:[^)]*' dist/assets/*.js"
block restore
session '~/planner' 'git checkout src/main.ts && rm .env.local'

# Typing.
block typo
session '~/planner' "sed -i 's/VITE_TITLE/VITE_TITEL/' src/env.ts" \
  'npm run build -- --mode staging 2>&1 | tail -1' "grep -o 'Study planner[^\`]*' dist/assets/*.js"
shown typing-the-variables.md src/vite-env.d.ts '~/planner/src/vite-env.d.ts'
block typed
session '~/planner' 'npm run build -- --mode staging'
block typed-fix
session '~/planner' 'git checkout src/env.ts' 'npm run build -- --mode staging 2>&1 | tail -1' \
  "grep -o 'Study planner[^\`]*' dist/assets/*.js" 'git add src/vite-env.d.ts' \
  'git commit -qm "Declare the variables the planner reads"'

# One build or many.
block hashes
session '~/planner' 'npm run build > /dev/null && ls dist/assets/*.js' \
  'npm run build -- --mode staging > /dev/null && ls dist/assets/*.js'

# A key that must stay secret.
shown a-key-that-must-stay-secret.md support-service.mjs '~/planner/support-service.mjs'
shown a-key-that-must-stay-secret.md support-proxy.mjs '~/planner/support-proxy.mjs'
block nokey
session '~/planner' 'node support-proxy.mjs'
bg svc '~/planner' 'node support-service.mjs'
bg proxy '~/planner' 'SUPPORT_TOKEN=tok-demo-not-a-real-secret node support-proxy.mjs'
wait_port 9000
wait_port 8787
block proxy-start
bg_show proxy
block tickets
session '~/planner' 'curl -s -X POST http://127.0.0.1:9000/tickets' \
  'curl -s -X POST http://127.0.0.1:8787/api/support' \
  "curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8787/anything-else"
bg_stop proxy INT
bg_stop svc INT
quiet '~/planner' 'rm support-service.mjs support-proxy.mjs'

# A leak.
block ignore
session '~/planner' 'git check-ignore -v .env.local .env'
block leak
session '~/planner' "echo 'SUPPORT_TOKEN=tok-demo-not-a-real-secret' > .env" 'git add .' \
  'git commit -qm "Support widget settings"' 'git show --stat --oneline HEAD'
block unleak
session '~/planner' 'git rm -q --cached .env' "echo '.env' >> .gitignore" \
  'git commit -qam "Keep .env out of the repository"' 'git ls-files .env .env.staging'
block history
session '~/planner' 'git log --oneline -p -- .env | head -12'
block undo
session '~/planner' 'git reset -q --hard HEAD~2 && rm .env' 'git log --oneline' 'git status --short'
quiet '~/planner' 'npm run build'
quiet '~/planner' 'git tag -f lesson-2'
