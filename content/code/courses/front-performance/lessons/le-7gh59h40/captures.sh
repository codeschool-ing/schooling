#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash ../../lab.sh up        (and lesson 1's captures, which make ~/planner)
#   bash captures.sh > /tmp/l2.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l2.txt; done
#
# THE FOUR PROJECTS are made by the four commands the section "Four projects,
# side by side" shows in a plain fence, typed exactly as there; their output is
# a progress report full of colours and cursor movements, which the lesson says
# it does not reproduce, so it goes to /dev/null here. Everything after that is
# typed at ana's prompt and printed as it came.
#
# STAGED: nothing beyond lab.sh's own staging. The files ana writes are taken
# out of the lesson's .md by lab/shown.py. Builds and servers run with no proxy
# in the environment (lab.sh offline), as on a student's computer.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L=$PWD
for n in nx nu sv ng ssr; do bg_stop $n; done
rm -rf /home/ana/meta

block ng22
session '~' 'npx --yes @angular/cli@22.2.4 version'

quiet '~' 'mkdir ~/meta'
quiet '~/meta' 'npx create-next-app@16.4.3 next --ts --app --empty --no-tailwind --no-eslint --no-react-compiler --no-src-dir --import-alias "@/*" --use-npm --disable-git --no-agents-md --no-agent-feedback </dev/null'
quiet '~/meta' 'npm create nuxt@4.0.1 nuxt -- --template minimal --packageManager npm --no-gitInit --modules= </dev/null'
quiet '~/meta' 'npx sv@1.1.1 create svelte --template minimal --types ts --add sveltekit-adapter="adapter:node" --install npm </dev/null'
quiet '~/meta' 'npx @angular/cli@21.2.28 new angular --ssr --defaults --skip-git --skip-tests --style=css --ai-config=none --skip-install </dev/null'
for d in next nuxt svelte angular; do [ -d /home/ana/meta/$d ] || { echo "the $d project was not made" >&2; exit 1; }; done

block ng-install
session '~/meta' 'cd angular' 'npm install' 'echo legacy-peer-deps=true > .npmrc' 'npm install'

shown $L/four-projects.md pin.mjs '~/meta/pin.mjs'
block pin
session '~/meta' 'for d in next nuxt svelte angular; do (cd $d && node ../pin.mjs && npm install --silent); done' \
  "grep -h -E '\"(next|nuxt|@sveltejs/kit|@angular/core)\":' */package.json" \
  'for d in next nuxt svelte; do cp ~/planner/public/courses.json $d/; done' \
  'cp ~/planner/public/courses.json angular/public/' \
  'du -sh */node_modules'
quiet '~/meta/next' 'npx next telemetry disable'
quiet '~/meta/angular' 'npx ng analytics disable'

# Next.js
for f in lib/plan.ts app/layout.tsx app/page.tsx 'app/courses/[slug]/page.tsx'; do
  shown $L/next.md "$f" "~/meta/next/$f"
done
block next-build
osession '~/meta/next' "npm run build 2>&1 | sed -n '/^Route/,\$p'"

# Nuxt
for f in server/api/plan.get.ts app/app.vue app/pages/index.vue 'app/pages/courses/[slug].vue' nuxt.config.ts; do
  shown $L/nuxt.md "$f" "~/meta/nuxt/$f"
done
block nuxt-build
osession '~/meta/nuxt' 'npm run build >/dev/null 2>&1; ls .output .output/server'

# SvelteKit
quiet '~/meta/svelte' 'rm src/lib/index.ts'
for f in src/lib/plan.ts src/routes/+page.server.ts src/routes/+page.svelte \
  'src/routes/courses/[slug]/+page.server.ts' 'src/routes/courses/[slug]/+page.svelte'; do
  shown $L/sveltekit.md "$f" "~/meta/svelte/$f"
done
block svelte-build
osession '~/meta/svelte' 'npm run check 2>&1 | tail -1' 'npm run build 2>&1 | tail -4' 'ls build build/client'

# Angular
quiet '~/meta/angular' 'rm src/app/app.html src/app/app.css'
for f in src/app/plan.ts src/app/home.ts src/app/course.ts src/app/app.ts src/app/app.routes.ts \
  src/app/app.routes.server.ts src/app/app.config.ts; do
  shown $L/angular.md "$f" "~/meta/angular/$f"
done
block ng-build
osession '~/meta/angular' "npm run build 2>&1 | grep -E 'Initial total|Prerendered'"
bg ng '~/meta/angular' 'PORT=3004 node dist/angular/server/server.mjs'
wait_port 3004
block ng-refused
osession '~/meta/angular' 'curl -s http://localhost:3004/courses/git | grep app-root'
sleep 0.5
block ng-log
bg_show ng
bg_stop ng INT
block ng-config
osession '~/meta/angular' "npx ng config projects.angular.architect.build.options.security.allowedHosts '[\"localhost\"]'" \
  "grep -A3 '\"security\"' angular.json" \
  "npm run build 2>&1 | grep -E 'Initial total|Prerendered'"

# The same page, four ways.
bg ssr '~/planner' 'npm run build >/dev/null && node server.ts'
bg nx '~/meta/next' 'npx next start -p 3001'
bg nu '~/meta/nuxt' 'PORT=3002 node .output/server/index.mjs'
bg sv '~/meta/svelte' 'PORT=3003 node build'
bg ng '~/meta/angular' 'PORT=3004 node dist/angular/server/server.mjs'
for p in 3000 3001 3002 3003 3004; do wait_port $p; done
block same
osession '~/planner' "for p in 3000 3001 3002 3003 3004; do curl -s http://localhost:\$p/courses/git | grep -o '<h1>Git</h1>'; done"
block status
osession '~/planner' "for p in 3000 3001 3002 3003 3004; do curl -s -o /dev/null -w \"\$p %{http_code}\\n\" http://localhost:\$p/courses/nonsense; done" \
  "curl -s http://localhost:3001/courses/nonsense | grep -o '<meta name=\"robots\"[^>]*>'"
shown $L/the-same-page.md tools/weigh.ts '~/planner/tools/weigh.ts'
block weigh
osession '~/planner' 'node tools/weigh.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git'
shown $L/the-data-it-sends.md tools/payload.ts '~/planner/tools/payload.ts'
block payload
osession '~/planner' 'node tools/payload.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git'
for n in nx nu sv ng ssr; do bg_stop $n INT; done
