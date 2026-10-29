#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l18.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l18.txt; done
#
# Starts from ~/vue as lesson 17 left it and makes ~/vue/planner-nuxt beside
# the planner. create-nuxt 4.0.1, Nuxt 4.6.2 and what it depends on come from
# the npm registry, and Node.js 22.23.4 from nodejs.org, which the lesson
# installs over 22.22.0 because Nuxt 4.6 asks for 22.22.3 or later; the minimal template create-nuxt downloads is the one of
# the day it ran, and every file of it the lesson keeps is shown whole. The
# files ana writes are taken whole out of the sections that show them.
#
# STAGED: the clock. The Nuxt server renders the week page as well as the
# browser, and a server has no --clock, so the dev server and every look run
# under libfaketime starting at 21 October 2026, 10:00 (lab/lib.sh, CLOCK).
# The lesson tells the student to run look without --clock from here on.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
N='~/vue/planner-nuxt'
at() { CLOCK='2026-10-21 10:00:00' "$@"; }  # on the staged clock
pages() {  # the files of the pages section
  shown pages.md app/app.vue $N/app/app.vue
  shown pages.md app/pages/index.vue $N/app/pages/index.vue
  shown pages.md 'app/pages/courses/[id].vue' "$N/app/pages/courses/[id].vue"
}
files() {
  if ! bash "$LAB_SH" script 'node --version' | grep -q v22.23.4; then
    quiet '~' 'curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz &&
      rm -rf ~/.local/node && mkdir ~/.local/node &&
      tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1 && rm node-v22.23.4-linux-x64.tar.xz'
  fi
  if [ ! -d /home/ana/vue/planner-nuxt/node_modules ]; then
    quiet '~/vue' 'npm create nuxt@4.0.1 -- planner-nuxt --template minimal --packageManager npm --no-gitInit --no-install'
    quiet $N 'npm install --save-exact nuxt@4.6.2 vue@3.5.44 vue-router@5.4.0'
  fi
  shown planner-in-nuxt.md nuxt.config.ts $N/nuxt.config.ts
  shown layouts.md app/app.vue $N/app/app.vue
  shown layouts.md app/layouts/default.vue $N/app/layouts/default.vue
  shown layouts.md app/error.vue $N/app/error.vue
  quiet $N 'mkdir -p shared/utils app/components app/assets server/data &&
    cp ../planner/src/planner.ts shared/utils/planner.ts &&
    sed -i "1s#src/planner.ts#shared/utils/planner.ts#" shared/utils/planner.ts &&
    cp ../planner/src/main.css app/assets/main.css &&
    cp ../planner/public/courses.json server/data/courses.json'
  shown auto-imports.md app/components/CourseCard.vue $N/app/components/CourseCard.vue
  shown auto-imports.md app/components/PlannerPanel.vue $N/app/components/PlannerPanel.vue
  shown auto-imports.md app/components/SessionRow.vue $N/app/components/SessionRow.vue
  shown server-routes.md server/utils/planner-data.ts $N/server/utils/planner-data.ts
  shown server-routes.md server/api/courses.get.ts $N/server/api/courses.get.ts
  shown server-routes.md 'server/api/sessions/[id].patch.ts' "$N/server/api/sessions/[id].patch.ts"
  shown planner-in-nuxt.md app/pages/index.vue $N/app/pages/index.vue
  shown planner-in-nuxt.md 'app/pages/courses/[id].vue' "$N/app/pages/courses/[id].vue"
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-tbmn65qd
# start_from restores ~/vue and not ~/.local: put back the Node lesson 1
# installed, in case an earlier run of this script left 22.23.4 there.
quiet '~' 'node --version | grep -q v22.22.0 || { curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz &&
  rm -rf ~/.local/node && mkdir ~/.local/node &&
  tar -xJf node-v22.22.0-linux-x64.tar.xz -C ~/.local/node --strip-components=1 && rm node-v22.22.0-linux-x64.tar.xz; }'
block create
session '~/vue' 'npm create nuxt@4.0.1 -- planner-nuxt --template minimal --packageManager npm --no-gitInit --no-install'
block tree
session $N 'find . -type f | sort' 'cat package.json'
block install
session $N 'npm install --save-exact nuxt@4.6.2 vue@3.5.44 vue-router@5.4.0'
block engines
session $N 'node --version' 'npm view nuxt@4.6.2 engines.node'
block node
session '~' 'curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz' \
  "curl -fsSL https://nodejs.org/dist/v22.23.4/SHASUMS256.txt | grep ' node-v22.23.4-linux-x64.tar.xz\$' | sha256sum -c" \
  'rm -rf ~/.local/node && mkdir ~/.local/node' \
  'tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1' \
  'rm node-v22.23.4-linux-x64.tar.xz' \
  'node --version' 'npm --version'
block reinstall
session $N 'npm install'
block audit
session $N 'npm audit'
block template
session $N 'cat nuxt.config.ts app/app.vue'
shown creating.md nuxt.config.ts $N/nuxt.config.ts
at dev nx $N 'npm run dev' 3000
sleep 3
block creating/dev
bg_show nx
block creating/welcome
at session $N "look http://localhost:3000/ --text body"

# pages
pages
sleep 2
block pages/pages-home
at session $N "look http://localhost:3000/ --text body"
block pages-click
at session $N "look http://localhost:3000/ --network --do 'click text=Spanish' --text body | grep -v '^net  GET /_nuxt/@'"
block pages-source
session $N "curl -s http://localhost:3000/courses/spanish | grep -o '<h1>[^<]*</h1>'"
block pages/pages-404
at session $N "look http://localhost:3000/courses/spanish/extra --text body"
block pages-log
bg_show nx

# layouts
shown layouts.md app/layouts/default.vue $N/app/layouts/default.vue
shown layouts.md app/app.vue $N/app/app.vue
shown layouts.md app/error.vue $N/app/error.vue
sleep 3
block layouts/layouts-home
at session $N "look http://localhost:3000/ --text body"
block layouts/layouts-404
at session $N "look http://localhost:3000/courses/spanish/extra --text body"

# auto-imports
block copy
session $N 'mkdir -p shared/utils app/components app/assets server/data' \
  'cp ../planner/src/planner.ts shared/utils/planner.ts' \
  "sed -i '1s#src/planner.ts#shared/utils/planner.ts#' shared/utils/planner.ts" \
  'cp ../planner/src/main.css app/assets/main.css' \
  'cp ../planner/public/courses.json server/data/courses.json'
for c in PlannerPanel CourseCard SessionRow; do shown auto-imports.md app/components/$c.vue $N/app/components/$c.vue; done
sleep 4
block imports-dts
session $N "grep -n 'shared/utils/planner' .nuxt/imports.d.ts .nuxt/types/imports.d.ts | cut -c1-140"
block auto-imports/components-dts
session $N "grep -n '\"../app/components' .nuxt/components.d.ts | cut -c1-120"

# server routes
shown server-routes.md server/utils/planner-data.ts $N/server/utils/planner-data.ts
shown server-routes.md server/api/courses.get.ts $N/server/api/courses.get.ts
shown server-routes.md 'server/api/sessions/[id].patch.ts' "$N/server/api/sessions/[id].patch.ts"
sleep 3
block api-get
session $N 'curl -s http://localhost:3000/api/courses | head -12'
block api-patch
session $N 'curl -s -X PATCH http://localhost:3000/api/sessions/s4' 'curl -s -X PATCH http://localhost:3000/api/sessions/s99' \
  "curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:3000/api/sessions/s4"
block server-routes/api-back
session $N 'curl -s -X PATCH http://localhost:3000/api/sessions/s4 | grep done'

# the planner
shown planner-in-nuxt.md nuxt.config.ts $N/nuxt.config.ts
shown planner-in-nuxt.md app/pages/index.vue $N/app/pages/index.vue
shown planner-in-nuxt.md 'app/pages/courses/[id].vue' "$N/app/pages/courses/[id].vue"
sleep 2
wait_port 3000
sleep 8
block planner-week
at session $N "look http://localhost:3000/ --text main"
block planner-tick
at session $N "look http://localhost:3000/ --do 'check label:has-text(\"21 October\") input' --do 'wait 500' --do 'goto /' --text 'main section:nth-child(3) footer'"
block planner-in-nuxt/api-back
session $N 'curl -s -X PATCH http://localhost:3000/api/sessions/s4 | grep done'
block planner-course
at session $N "look http://localhost:3000/courses/spanish --text main"
block planner-missing
at session $N "look http://localhost:3000/courses/piano --text main"
bg_stop nx
snapshot

