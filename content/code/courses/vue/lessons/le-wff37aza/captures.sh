#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l20.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l20.txt; done
#
# Starts from ~/vue as lesson 19 left it, on Node 22.23.4. The files ana
# writes are taken whole out of the sections that show them; the edits made
# for a demonstration and undone after it are sed, as the lesson types them.
#
# STAGED: the clock, as in lesson 18 (lab/lib.sh, CLOCK): the dev server and
# every look start at 21 October 2026, 10:00. The dev server is started
# afresh where a section shows its terminal, so each one shows the requests
# of that section only; the lesson says to restart it there.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
N='~/vue/planner-nuxt'
at() { CLOCK='2026-10-21 10:00:00' "$@"; }
node22() {
  bash "$LAB_SH" script 'node --version' | grep -q v22.23.4 && return
  quiet '~' 'curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz &&
    rm -rf ~/.local/node && mkdir ~/.local/node &&
    tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1 && rm node-v22.23.4-linux-x64.tar.xz'
}
restart() { bg_stop nx; at dev nx $N 'npm run dev' 3000; sleep 6; }
files() {
  node22
  shown use-fetch.md server/middleware/log.ts $N/server/middleware/log.ts
  shown use-fetch.md nuxt.config.ts $N/nuxt.config.ts
  shown use-async-data.md app/layouts/default.vue $N/app/layouts/default.vue
  shown keys.md 'server/api/courses/[id].get.ts' "$N/server/api/courses/[id].get.ts"
  shown keys.md 'app/pages/courses/[id].vue' "$N/app/pages/courses/[id].vue"
  shown refresh-and-errors.md app/pages/index.vue $N/app/pages/index.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-cxe3gm42
node22

# useFetch
shown use-fetch.md server/middleware/log.ts $N/server/middleware/log.ts
shown use-fetch.md nuxt.config.ts $N/nuxt.config.ts
restart
block use-fetch/week
at session $N "look http://localhost:3000/ --network --text - | grep '/api/'"
block use-fetch/log
bg_show nx
block use-fetch/click
at session $N "look http://localhost:3000/ --network --do 'click text=Spanish' --text - | grep '/api/'"

# useAsyncData
shown use-async-data.md app/layouts/default.vue $N/app/layouts/default.vue
restart
block footer
at session $N "look http://localhost:3000/ --text '#__nuxt > footer'"
block use-async-data/log
bg_show nx

# the payload
block payload-scripts
session $N "curl -s http://localhost:3000/ | grep -o '<script type=\"application/json\"[^>]*>'"
block payload-start
session $N "curl -s http://localhost:3000/ | grep -o 'id=\"__NUXT_DATA__\">[^<]*' | cut -c1-420"
block payload-keys
session $N "curl -s http://localhost:3000/ | grep -o 'id=\"__NUXT_DATA__\">[^<]*' | grep -o '\"session-count\":-\\?[0-9]*\\|\"\\\$f[a-z0-9]*\":-\\?[0-9]*'"
block payload-size
session $N 'curl -s http://localhost:3000/ | wc -c' "curl -s http://localhost:3000/ | grep -o 'id=\"__NUXT_DATA__\">[^<]*' | wc -c" 'curl -s http://localhost:3000/api/courses | wc -c'

# the double fetch
quiet $N 'mkdir -p app/pages/demo'
shown double-fetch.md app/pages/demo/twice.vue $N/app/pages/demo/twice.vue
shown double-fetch.md app/pages/demo/mounted.vue $N/app/pages/demo/mounted.vue
restart
block twice
at session $N "look http://localhost:3000/demo/twice --network --text main | grep -v '^net  GET /_nuxt'"
block double-fetch/log
bg_show nx
block mounted
session $N "curl -s http://localhost:3000/demo/mounted | grep -o '<p>[^<]*</p>'"
block double-fetch/rm
session $N 'rm -r app/pages/demo'

# keys
shown keys.md 'server/api/courses/[id].get.ts' "$N/server/api/courses/[id].get.ts"
shown keys.md 'app/pages/courses/[id].vue' "$N/app/pages/courses/[id].vue"
quiet $N 'mkdir -p app/pages/demo'
shown keys.md app/pages/demo/clash.vue $N/app/pages/demo/clash.vue
restart
block two-courses
at session $N "look http://localhost:3000/ --network --do 'click text=Spanish' --do 'click .brand a' --do 'click text=Guitar' --text main | grep '/api/\\|^-- '"
block clash
at session $N "look http://localhost:3000/demo/clash --text main"
block keys/rm
session $N 'rm -r app/pages/demo'

# refresh and errors
block maintenance
session $N "sed -i \"s#=> planner)#=> {\\n  throw createError({ statusCode: 503, statusMessage: 'Down for maintenance' })\\n})#\" server/api/courses.get.ts"
sleep 2
block maintenance-before
at session $N "look http://localhost:3000/ --text main"
shown refresh-and-errors.md app/pages/index.vue $N/app/pages/index.vue
sleep 2
block maintenance-after
at session $N "look http://localhost:3000/ --text main"
shown refresh-and-errors.md server/api/courses.get.ts $N/server/api/courses.get.ts
sleep 2
block piano
at session $N "look http://localhost:3000/courses/piano --text main"

# lazy
block slow
session $N "sed -i 's#defineEventHandler((event) => {#defineEventHandler(async (event) => {\\n  await new Promise((resolve) => setTimeout(resolve, 2000))#' 'server/api/courses/[id].get.ts'"
sleep 2
block waits
at session $N "look http://localhost:3000/ --do 'click text=Spanish' --text 'main h1'"
block lazy-on
session $N "sed -i 's#useFetch(() => \`/api/courses/\${route.params.id}\`)#useFetch(() => \`/api/courses/\${route.params.id}\`, { lazy: true })#' 'app/pages/courses/[id].vue'"
sleep 2
block lazy-look
at session $N "look http://localhost:3000/ --do 'click text=Spanish' --text main" "look http://localhost:3000/ --do 'click text=Spanish' --do 'wait 2500' --text main"
block lazy-off
session $N "sed -i 's#, { lazy: true })#)#' 'app/pages/courses/[id].vue'" \
  "sed -i '/setTimeout(resolve, 2000)/d; s#async (event)#(event)#' 'server/api/courses/[id].get.ts'"
bg_stop nx
snapshot
