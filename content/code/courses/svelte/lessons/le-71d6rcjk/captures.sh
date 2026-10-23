#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l8.txt
#   F="python3 ../../lab/fill.py"
#   $F if-blocks.md /tmp/l8.txt --blocks if-now,if-before,if-after
#   $F each-blocks.md /tmp/l8.txt --blocks days-stale,days-next,days
#   $F keyed-each.md /tmp/l8.txt --blocks unkeyed,keyed
#   $F await-blocks.md /tmp/l8.txt --blocks mv,ssr-fetch,ssr-fetch-dev,loading-html,loaded,catch
#   $F key-blocks.md /tmp/l8.txt --blocks no-key,with-key
#
# It starts from the project as lesson 7 committed it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; the pieces the
# prose tells her to add to a file ("this block, just under …") are taken
# out of the .md the same way, by fence number, and put exactly where the
# sentence says, by `put` below.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 7
P=/home/ana/planner/src/routes/+page.svelte

# fence MD N: the N-th fenced block of MD (1-based), without its fence lines.
fence() { python3 -c 'import re,sys; b=re.findall(r"^```[a-z-]*\n(.*?)^```$", open(sys.argv[1]).read(), re.S|re.M); sys.stdout.write(b[int(sys.argv[2])-1])' "$1" "$2"; }
# put FILE AFTER|BEFORE ANCHOR TEXT INDENT: insert TEXT, each line indented by
# INDENT tabs, after (or before) the one line of FILE that equals ANCHOR.
put() {
  python3 - "$@" <<'PY'
import sys
f, where, anchor, text, indent = sys.argv[1:6]
lines = open(f).read().split("\n")
hits = [i for i, l in enumerate(lines) if l == anchor]
assert len(hits) == 1, (anchor, hits)
block = ["\t" * int(indent) + l if l else l for l in text.rstrip("\n").split("\n")]
i = hits[0] + (1 if where == "after" else 0)
lines[i:i] = block
open(f, "w").write("\n".join(lines))
PY
}
# replace FILE OLD NEW: one exact occurrence of OLD becomes NEW.
replace() { python3 -c 'import sys; f,o,n=sys.argv[1:]; t=open(f).read(); assert t.count(o)==1,o; open(f,"w").write(t.replace(o,n))' "$@"; }

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

put $P after $'\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));' "$(fence if-blocks.md 1)" 1
put $P after $'\t<WeekTotal minutes={total} />' "$(fence if-blocks.md 2)" 1
sleep 1
block if-now
session '~/planner' 'look http://localhost:5173/'
block if-before
session '~/planner' "look http://localhost:5173/ --click 'Previous week'"
block if-after
session '~/planner' "look http://localhost:5173/ --click 'Next week'"

put $P after $'\tlet doneMinutes = $derived(thisWeek.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0));' "$(fence each-blocks.md 1)" 1
put $P after $'\t{/if}' "$(fence each-blocks.md 2)" 1
sleep 1
block days-stale
session '~/planner' "look http://localhost:5173/ --click 'Next week'"
replace $P '{const day = addDays(week, i)}' '{const day = $derived(addDays(week, i))}'
sleep 1
block days-next
session '~/planner' "look http://localhost:5173/ --click 'Next week'"
block days
session '~/planner' 'look http://localhost:5173/'

shown keyed-each.md 'src/routes/keys/+page.svelte#1' '~/planner/src/routes/keys/+page.svelte'
sleep 1
block unkeyed
session '~/planner' "look http://localhost:5173/keys --fill 'Note for 19 Oct=read chapter 3' --click 'Shortest first'"
shown keyed-each.md 'src/routes/keys/+page.svelte#2' '~/planner/src/routes/keys/+page.svelte'
sleep 1
block keyed
session '~/planner' "look http://localhost:5173/keys --fill 'Note for 19 Oct=read chapter 3' --click 'Shortest first'"
quiet '~/planner' 'rm -r src/routes/keys'

block mv
session '~/planner' 'git mv src/lib/planner.json static/planner.json'
shown await-blocks.md src/lib/Planner.svelte '~/planner/src/lib/Planner.svelte'
bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173
shown await-blocks.md 'src/routes/+page.svelte#1' '~/planner/src/routes/+page.svelte'
sleep 1
block ssr-fetch
session '~/planner' 'look http://localhost:5173/'
sleep 1
block ssr-fetch-dev
bg_show dev
shown await-blocks.md 'src/routes/+page.svelte#2' '~/planner/src/routes/+page.svelte'
sleep 1
block loading-html
session '~/planner' "curl -s http://localhost:5173/ | grep -o '<main.*</main>'"
block loaded
session '~/planner' 'look http://localhost:5173/'
replace $P "fetch('/planner.json')" "fetch('/planer.json')"
sleep 1
block catch
session '~/planner' 'look http://localhost:5173/'
shown await-blocks.md 'src/routes/+page.svelte#2' '~/planner/src/routes/+page.svelte'

sleep 1
block no-key
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --click 'Next week'"
replace /home/ana/planner/src/lib/Planner.svelte $'\t<AddSession onadd={add} />\n' $'\t{#key week}\n\t\t<AddSession onadd={add} />\n\t{/key}\n'
sleep 1
block with-key
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --click 'Next week'"
done_lesson 8 "control flow, and the planner loaded with {#await}"
