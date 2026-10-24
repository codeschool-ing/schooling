#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l19.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l19.txt; done
#
# Starts from ~/vue as lesson 18 left it, on Node 22.23.4. The files ana
# writes are taken whole out of the sections that show them.
#
# STAGED: the clock, as in lesson 18 (lab/lib.sh, CLOCK). Every server and
# every look starts at 21 October 2026, 10:00 in São Paulo, except in the
# hydration sections, which start at 23:30 that day and give the server the
# zone UTC (SERVER_TZ), where it is already 02:30 on the 22nd: a server in
# another zone from its readers is the ordinary case, and these sections are
# about what it does. The server's zone is the environment's and is not
# typed; the lesson says so.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
N='~/vue/planner-nuxt'
at() { CLOCK='2026-10-21 10:00:00' "$@"; }                      # the morning, one zone
late() { CLOCK='2026-10-21 23:30:00' SERVER_TZ=UTC "$@"; }      # the night, two zones
node22() {
  bash "$LAB_SH" script 'node --version' | grep -q v22.23.4 && return
  quiet '~' 'curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz &&
    rm -rf ~/.local/node && mkdir ~/.local/node &&
    tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1 && rm node-v22.23.4-linux-x64.tar.xz'
}
files() {
  node22
  shown route-rules.md nuxt.config.ts $N/nuxt.config.ts
  shown route-rules.md app/pages/about.vue $N/app/pages/about.vue
  shown client-only.md app/layouts/default.vue $N/app/layouts/default.vue
  shown client-only.md app/pages/index.vue $N/app/pages/index.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-f9azt3xg
node22

# csr: the Vite planner's build, as lesson 17 left it
quiet $P 'npm run build'
dev pv $P 'npm run preview' 4173
block csr-curl
session $P 'curl -s http://localhost:4173/courses/spanish'
block csr-nojs
session $P "look http://localhost:4173/ --no-js --text body"
bg_stop pv

# ssr
at dev nx $N 'npm run dev' 3000
sleep 6
block ssr-nojs
at session $N "look http://localhost:3000/ --no-js --text 'main section:nth-child(3)'"
block ssr-nojs-tick
at session $N "look http://localhost:3000/ --no-js --do 'check label:has-text(\"21 October\") input' --do 'goto /' --text 'main section:nth-child(3) footer'"
block ssr-js
at session $N "look http://localhost:3000/ --network --text - | grep -v '^net  GET /_nuxt/@' | grep -c '^net'"
bg_stop nx
block ssr-build
session $N 'npm run build 2>&1 | tail -3'
block ssr-du
session $N 'du -sh .output' 'ls .output .output/server/node_modules'
at dev pr $N 'node .output/server/index.mjs' 3000
block ssr-prod
bg_show pr
block ssr-prod-look
at session $N "look http://localhost:3000/ --network --text - | grep '^net'"
bg_stop pr

# hydration
late dev nx $N 'npm run dev' 3000
sleep 6
block hydration-mismatch/hydration-dev
late session $N "look http://localhost:3000/ --text 'main section:nth-child(3) ul'"
bg_stop nx
late dev pr $N 'node .output/server/index.mjs' 3000
block hydration-mismatch/hydration-prod
late session $N "look http://localhost:3000/ --text 'li.today'" "look http://localhost:3000/ --text 'li:has(strong)'"
bg_stop pr

# ssg
block generate
at session $N 'npx nuxt generate 2>&1 | tail -12'
block generate-ls
session $N 'ls .output/public .output/public/courses'
block generate-today
session $N "grep -o '<li class=\"today\"[^>]*><label[^>]*><input[^>]*>[^<]*' .output/public/index.html"

# route rules
shown route-rules.md nuxt.config.ts $N/nuxt.config.ts
shown route-rules.md app/pages/about.vue $N/app/pages/about.vue
block rules-build
session $N 'npm run build 2>&1 | grep -i prerender' 'ls .output/public'
at dev pr $N 'node .output/server/index.mjs' 3000
block rules-api
session $N "curl -s -D - -o /dev/null http://localhost:3000/api/courses | grep -i cache-control" "curl -s -D - -o /dev/null http://localhost:3000/courses/spanish | grep -i cache-control"
block rules-swr
session $N "curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l" \
  "curl -s -w '\\n' -X PATCH http://localhost:3000/api/sessions/s6" \
  "curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l"
block rules-swr-later
session $N 'sleep 60' \
  "curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l" \
  "curl -s http://localhost:3000/courses/spanish | grep -o '<input[^>]*checked' | wc -l"
bg_stop pr

# client-only
shown client-only.md app/layouts/default.vue $N/app/layouts/default.vue
shown client-only.md app/pages/index.vue $N/app/pages/index.vue
late dev nx $N 'npm run dev' 3000
sleep 6
block client-only/client-dev
late session $N "look http://localhost:3000/ --text 'li.today'" "look http://localhost:3000/ --text '#__nuxt > footer'"
block client-curl
session $N "curl -s http://localhost:3000/ | grep -o 'Days are counted in [^<]*'"
bg_stop nx
quiet $N 'npm run build'
snapshot
