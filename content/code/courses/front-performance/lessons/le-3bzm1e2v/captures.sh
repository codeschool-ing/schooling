#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of front-performance, as a script
# that produces them. Its output is pasted into the lesson by lab/fill.py and
# not committed.
#
#   bash captures.sh > /tmp/l4.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l4.txt; done
#
# It starts from ~/planner and ~/meta as lesson 3 left them. Files the lesson
# shows whole are taken out of it by lab/shown.py. The two edits it shows as a
# fragment, the lines of server.ts that build the page and the line of view.ts
# that defines day, are made here with the fragment taken out of the lesson
# too, replacing the line it says to replace. The one-second waits in stream.ts
# and in the two /slow pages are in their code, and the lesson says what they
# stand for.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L=$PWD
for n in ssr nx nu sv ng str st; do bg_stop $n; done
long_wait() { for _ in $(seq 900); do (exec 3<>/dev/tcp/127.0.0.1/$1) 2>/dev/null && return 0; sleep 0.2; done; echo "nothing on $1" >&2; }
fence() { python3 - "$1" "$2" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
for m in re.finditer(r"^```[a-z]*\n(.*?)^```$", text, re.S | re.M):
    if m.group(1).lstrip().startswith(sys.argv[2]):
        sys.stdout.write(m.group(1)); break
else:
    sys.exit("no fence starting " + sys.argv[2])
PY
}
# replace FILE OLDLINE-START NEWTEXT: the line of FILE that starts with OLD becomes NEW.
replace_line() { python3 - "$1" "$2" "$3" <<'PY'
import sys
path, old, new = sys.argv[1:]
lines = open(path).read().split("\n")
hits = [i for i, l in enumerate(lines) if l.startswith(old)]
if len(hits) != 1: sys.exit(f"{path}: {len(hits)} lines start with {old!r}")
lines[hits[0]:hits[0] + 1] = new.rstrip("\n").split("\n")
open(path, "w").write("\n".join(lines))
PY
}

# Hydrating the planner, from server.ts as lesson 1 wrote it.
shown $L/../le-3s959ek5/server-side.md server.ts '~/planner/server.ts'
replace_line /home/ana/planner/server.ts "  const html = shell.replace(" "$(fence $L/hydrating-the-planner.md '// The plan goes into the page')"
shown $L/hydrating-the-planner.md src/main.ts '~/planner/src/main.ts'
shown $L/hydrating-the-planner.md src/view.ts '~/planner/src/view.ts'
shown $L/hydrating-the-planner.md tools/hydrate.ts '~/planner/tools/hydrate.ts'
chown ana:ana /home/ana/planner/server.ts
bg ssr '~/planner' 'npm run build && TZ=UTC node server.ts'
long_wait 3000
block mismatch
osession '~/planner' "curl -s http://localhost:3000/courses/git | grep -o '<li>[^<]*'" \
  'node tools/hydrate.ts http://localhost:3000/courses/git' \
  'node tools/look.ts http://localhost:3000/courses/git | grep requests'
bg_stop ssr INT

# The fix.
replace_line /home/ana/planner/src/view.ts "const day = " "$(fence $L/a-mismatch.md 'const day = ')"
chown ana:ana /home/ana/planner/src/view.ts
bg ssr '~/planner' 'npm run build && TZ=UTC node server.ts'
long_wait 3000
block fixed
osession '~/planner' 'node tools/hydrate.ts http://localhost:3000/courses/git'
block dead
osession '~/planner' 'node tools/hydrate.ts http://localhost:3000/courses/git --script-delay 2000 --click-at 300'

# What it costs, against the four of lesson 2 as lesson 3 left them.
quiet '~/meta/next' 'npm run build'
quiet '~/meta/svelte' 'npm run build'
bg nx '~/meta/next' 'npx next start -p 3001'
bg nu '~/meta/nuxt' 'PORT=3002 node .output/server/index.mjs'
bg sv '~/meta/svelte' 'PORT=3003 node build'
bg ng '~/meta/angular' 'PORT=3004 node dist/angular/server/server.mjs'
for p in 3001 3002 3003 3004; do long_wait $p; done
shown $L/what-it-costs.md tools/cpu.ts '~/planner/tools/cpu.ts'
block cpu
osession '~/planner' 'node tools/cpu.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git'
for n in nx nu sv ng; do bg_stop $n INT; done

# Streaming.
shown $L/streaming-html.md stream.ts '~/planner/stream.ts'
shown $L/streaming-html.md tools/chunks.ts '~/planner/tools/chunks.ts'
bg str '~/planner' 'node stream.ts'
long_wait 3005
block chunks
osession '~/planner' 'node tools/chunks.ts http://localhost:3005/courses/git' 'node tools/chunks.ts http://localhost:3005/courses/nonsense'
shown $L/out-of-order.md tools/appear.ts '~/planner/tools/appear.ts'
block appear
osession '~/planner' 'node tools/appear.ts http://localhost:3005/courses/git Git "Loading sessions" 2026-10-24' \
  'node tools/appear.ts http://localhost:3005/courses/git Git "Loading sessions" 2026-10-24 --no-js'
block headers
osession '~/planner' "curl -si http://localhost:3005/courses/git | sed '/^\r\$/q'"

# Async components.
shown $L/async-components.md app/slow/page.tsx '~/meta/next/app/slow/page.tsx'
block next-slow-build
osession '~/meta/next' "npm run build 2>&1 | grep slow"
bg nx '~/meta/next' 'npx next start -p 3001'
long_wait 3001
block next-slow
osession '~/planner' 'node tools/chunks.ts http://localhost:3001/slow'
shown $L/async-components.md src/routes/slow/+page.server.ts '~/meta/svelte/src/routes/slow/+page.server.ts'
shown $L/async-components.md src/routes/slow/+page.svelte '~/meta/svelte/src/routes/slow/+page.svelte'
quiet '~/meta/svelte' 'npm run build'
bg sv '~/meta/svelte' 'PORT=3003 node build'
long_wait 3003
block svelte-slow
osession '~/planner' 'node tools/chunks.ts http://localhost:3003/slow'
for n in nx sv str ssr; do bg_stop $n INT; done
