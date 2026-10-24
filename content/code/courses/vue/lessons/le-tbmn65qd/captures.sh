#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l17.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l17.txt; done
#
# Starts from the planner as lesson 16 left it. create-vite 9.3.1 is fetched
# from the npm registry for its --help. vite.config.js, the plugin, .env,
# env.d.ts and AppFooter.vue are taken whole out of the sections that show
# them; the store's one-line change is applied with sed as env.md types it.
# The edits the HMR section makes while a page is open are made by look's
# `run` action, with sed, and undone the same way.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
files() {
  shown plugins.md vite.config.js $P/vite.config.js
  shown plugins.md plugins/check-planner-data.js $P/plugins/check-planner-data.js
  quiet $P 'rm -f jsconfig.json'
  shown env.md .env $P/.env
  shown env.md env.d.ts $P/env.d.ts
  shown env.md src/components/AppFooter.vue $P/src/components/AppFooter.vue
  quiet $P "sed -i \"s#fetch('/courses.json')#fetch(import.meta.env.VITE_DATA_URL)#\" src/stores/planner.ts"
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-cebqab6q
block version
session $P 'npx vite --version'
block create-help
session '~/vue' 'npm create vite@9.3.1 -- --help'
block rolldown
session $P 'npm ls rolldown'

dev pl $P 'npm run dev' 5173
block dev-server/ready
bg_show pl
block requests
session $P "look http://localhost:5173/ --network --text - | grep -c '^net'"
block served-ts
session $P 'curl -s http://localhost:5173/src/planner.ts | head -24'
block served-main
session $P "curl -s http://localhost:5173/src/main.ts | grep '^import'"
block deps
session $P 'ls node_modules/.vite/deps'

block hmr-template
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i \"s#<h1>This week</h1>#<h1>This study week</h1>#\" src/views/HomeView.vue' --do 'wait 1000' --text 'main h1' --html 'main section:nth-child(3) h2'"
block hmr-script
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i \"s#^const monday = ref#// The Monday whose week the page shows.\nconst monday = ref#\" src/views/HomeView.vue' --do 'wait 1000' --text 'main h1' --html 'main section:nth-child(3) h2'"
block hmr-full
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i \"1s#^#// Dates, weeks and totals.\\n#\" src/planner.ts' --do 'wait 1000' --text - --html 'main section:nth-child(3) h2'"
block hmr/hmr-log
bg_show pl
quiet $P "sed -i 's#<h1>This study week</h1>#<h1>This week</h1>#' src/views/HomeView.vue; sed -i '/^\/\/ The Monday whose week the page shows.$/d' src/views/HomeView.vue; sed -i '1d' src/planner.ts"
bg_stop pl

block build
session $P 'npm run build'
block dist
session $P 'ls -R dist'
block dist-html
session $P 'cat dist/index.html'
dev pv $P 'npm run preview' 4173
block preview-log
bg_show pv
block preview-requests
session $P "look http://localhost:4173/ --network --text '#app > footer'"
block preview-deep
session $P 'curl -sI http://localhost:4173/courses/spanish | head -3'
bg_stop pv

# config: the shown vite.config.js, then two dev servers at once
shown config.md vite.config.js $P/vite.config.js
dev pl $P 'npm run dev' 5173
block jsconfig
session $P 'rm jsconfig.json'
block config/strict
session $P 'npm run dev'
bg_stop pl

# env
shown env.md .env $P/.env
shown env.md env.d.ts $P/env.d.ts
shown env.md src/components/AppFooter.vue $P/src/components/AppFooter.vue
block store-env
session $P "sed -i \"s#fetch('/courses.json')#fetch(import.meta.env.VITE_DATA_URL)#\" src/stores/planner.ts" 'grep -n VITE_ src/stores/planner.ts'
block env-check
session $P 'npm run type-check'
block env-typo
session $P "sed -i 's/VITE_DATA_URL/VITE_DATA_ULR/' src/stores/planner.ts" 'npm run type-check'
quiet $P "sed -i 's/VITE_DATA_ULR/VITE_DATA_URL/' src/stores/planner.ts"
dev pl $P 'npm run dev' 5173
block env-dev
session $P "look http://localhost:5173/ --text '#app > footer'"
bg_stop pl
block env-secret
session $P "echo 'PLANNER_NOTE=not-for-the-browser' >> .env" 'npm run build > /dev/null' \
  "grep -c 'courses.json' dist/assets/index-*.js" "cat dist/assets/*.js | grep -c 'not-for-the-browser'"
quiet $P "sed -i '/^PLANNER_NOTE=/d' .env"
dev pv $P 'npm run preview' 4173
block env-preview
session $P "look http://localhost:4173/ --text '#app > footer'"
bg_stop pv
block env-mode
session $P "echo 'VITE_DATA_URL=/staging.json' > .env.staging" 'npx vite build --mode staging > /dev/null' \
  "grep -o '/[a-z]*\.json' dist/assets/index-*.js" 'rm .env.staging' 'npm run build > /dev/null'

# plugins
shown plugins.md vite.config.js $P/vite.config.js
shown plugins.md plugins/check-planner-data.js $P/plugins/check-planner-data.js
block plugin-good
session $P 'npm run build 2>&1 | tail -3'
block plugin-build
session $P "sed -i 's/\"course\": \"guitar\"/\"course\": \"piano\"/' public/courses.json" 'npm run build'
block plugins/plugin-dev
session $P 'npm run dev'
block plugin-back
session $P "sed -i 's/\"course\": \"piano\"/\"course\": \"guitar\"/' public/courses.json" 'npm run build 2>&1 | tail -3'
snapshot
