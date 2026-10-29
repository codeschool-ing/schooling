#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l3.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l3.txt; done
#
# It starts from ~/planner and ~/meta as lessons 1 and 2 left them. The edits
# the lesson asks for are made here as ana would make them: a file the lesson
# shows whole is taken out of the lesson by lab/shown.py; the one-line change
# to cacheLife and every change to a title are made with sed, and undone with
# sed, as the lesson says to undo them. Waiting ten seconds for a copy to go
# stale is a `sleep 11` typed at the prompt.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L=$PWD
M=$L/../le-7gh59h40
for n in st nx nu sv ng ssr pv; do bg_stop $n; done
long_wait() { for _ in $(seq 900); do (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0; sleep 0.2; done; echo "nothing on $1" >&2; }
quiet '~/planner' 'rm -f gen.ts prerender.ts static.ts; npm pkg delete scripts.build:static'

shown $L/prerender-the-planner.md prerender.ts '~/planner/prerender.ts'
shown $L/prerender-the-planner.md static.ts '~/planner/static.ts'
block pkgset
osession '~/planner' 'npm pkg set scripts.build:static="npm run build && node prerender.ts"' \
  'npm run build:static 2>&1 | tail -6' "find dist -name '*.html' | sort"
bg st '~/planner' 'npm run build:static && node static.ts'
long_wait 8080
block static-curl
osession '~/planner' "curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'" \
  "curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/courses/nonsense" \
  "curl -s http://localhost:8080/courses/nonsense | grep -o '<h1>[^<]*</h1>'" \
  'node tools/look.ts http://localhost:8080/ --no-js | head -3'
block stale
osession '~/planner' "sed -i 's/\"title\": \"Git\"/\"title\": \"Git and GitHub\"/' public/courses.json" \
  "grep -o '\"title\": \"Git[^\"]*\"' public/courses.json" \
  "curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'"
block rebuild
osession '~/planner' "npm run build:static >/dev/null && curl -s http://localhost:8080/courses/git | grep -o '<h1>[^<]*</h1>'"
quiet '~/planner' "sed -i 's/\"title\": \"Git and GitHub\"/\"title\": \"Git\"/' public/courses.json"
shown $L/what-goes-stale.md gen.ts '~/planner/gen.ts'
block gen
osession '~/planner' "TIMEFORMAT='%R s'; for n in 100 1000 5000; do npm run build >/dev/null && node gen.ts \$n && time node prerender.ts >/dev/null; done"
quiet '~/planner' 'npm run build:static'
bg_stop st INT

# The four prerender.
block next-files
osession '~/meta/next' "npm run build >/dev/null 2>&1; find .next/server/app -name '*.html' | sort"
block nuxt-files
osession '~/meta/nuxt' "npm run generate >/dev/null 2>&1; find .output/public -name '*.html' | sort"
shown $L/the-four-prerender.md src/routes/+layout.server.ts '~/meta/svelte/src/routes/+layout.server.ts'
block svelte-files
osession '~/meta/svelte' "npm run build >/dev/null 2>&1; find build/prerendered -name '*.html' | sort"
shown $L/the-four-prerender.md src/app/app.routes.server.ts '~/meta/angular/src/app/app.routes.server.ts'
block ng-files
osession '~/meta/angular' "npm run build 2>&1 | grep Prerendered; find dist/angular/browser -name '*.html' | sort"

# Regeneration by age, in Next.js.
LOOKNX="look() { curl -s -D - -o /tmp/page.html http://localhost:3001/courses/git | grep -iE '^(x-nextjs-cache|cache-control):'; grep -o '<h1>[^<]*</h1>' /tmp/page.html; }"
quiet '~/meta/next' "sed -i 's/  cacheLife(\"hours\");/  cacheLife({ revalidate: 10, expire: 3600 });/' lib/plan.ts"
block next-isr-build
osession '~/meta/next' "npm run build 2>&1 | sed -n '/^Route/,\$p' | head -8"
bg nx '~/meta/next' 'npx next start -p 3001'
long_wait 3001
block next-isr
osession '~/meta/next' "$LOOKNX" 'look' \
  "sed -i 's/\"title\": \"Git\"/\"title\": \"Git and GitHub\"/' courses.json" 'look' 'sleep 11; look' 'sleep 1; look'
bg_stop nx INT
quiet '~/meta/next' "sed -i 's/\"title\": \"Git and GitHub\"/\"title\": \"Git\"/' courses.json; sed -i 's/  cacheLife({ revalidate: 10, expire: 3600 });/  cacheLife(\"hours\");/' lib/plan.ts"

# On demand.
shown $L/on-demand.md lib/plan.ts '~/meta/next/lib/plan.ts'
shown $L/on-demand.md app/api/revalidate/route.ts '~/meta/next/app/api/revalidate/route.ts'
bg nx '~/meta/next' 'npm run build && REVALIDATE_SECRET=s3cret npx next start -p 3001'
long_wait 3001
block on-demand
osession '~/meta/next' "sed -i 's/\"title\": \"Git\"/\"title\": \"Git and GitHub\"/' courses.json" \
  'curl -s -X POST http://localhost:3001/api/revalidate' \
  "curl -s -X POST -H 'x-revalidate-secret: s3cret' http://localhost:3001/api/revalidate" \
  "curl -s http://localhost:3001/courses/git | grep -o '<h1>[^<]*</h1>'" \
  "curl -s http://localhost:3001/courses/git | grep -o '<h1>[^<]*</h1>'" \
  "curl -s http://localhost:3001/ | grep -o '>Git[^<]*</a>'"
bg_stop nx INT
quiet '~/meta/next' "sed -i 's/\"title\": \"Git and GitHub\"/\"title\": \"Git\"/' courses.json"

# Nuxt.
shown $L/isr-in-nuxt.md nuxt.config.ts '~/meta/nuxt/nuxt.config.ts'
quiet '~/meta/nuxt' 'npm run build'
bg nu '~/meta/nuxt' 'PORT=3002 node .output/server/index.mjs'
long_wait 3002
LOOKNU="look() { curl -s -D - -o /tmp/page.html http://localhost:3002/courses/git | grep -iE '^(cache-control|last-modified):'; grep -o '<h1>[^<]*</h1>' /tmp/page.html; }"
block nuxt-isr
osession '~/meta/nuxt' "$LOOKNU" 'look' \
  "sed -i 's/\"title\": \"Git\"/\"title\": \"Git and GitHub\"/' courses.json" 'look' 'sleep 11; look' 'sleep 1; look'
bg_stop nu INT
quiet '~/meta/nuxt' "sed -i 's/\"title\": \"Git and GitHub\"/\"title\": \"Git\"/' courses.json"
shown $M/nuxt.md nuxt.config.ts '~/meta/nuxt/nuxt.config.ts'
quiet '~/meta/nuxt' 'npm run build'
