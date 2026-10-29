#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l3.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l3.txt; done
#
# Starts from the planner and the sandbox as lesson 2 left them. Every demo
# and every file of the planner is taken out of the section that shows it.
# The browser's clock is set to 2026-10-21 with look's --clock, so the week
# on screen is the week of the data.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="computed:ComputedTotal caching:LazyComputed writable:WritableHours wrong-tool:SyncedByWatch pure:SortInPlace pure:AsyncComputed"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown week-total.md src/planner.js $P/src/planner.js
  shown week-total.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-nsq9gaqq
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block total
look_demo ComputedTotal "--do 'click button'"
block lazy
look_demo LazyComputed "--do 'click #change' --do 'click #show' --do 'click #change'"
block writable
look_demo WritableHours "--do 'click #two' --do 'click #three'"
block synced
look_demo SyncedByWatch "--do 'click #push' --do 'click #replace'"
block sort
look_demo SortInPlace
block async
look_demo AsyncComputed
bg_stop sb

dev pl $P 'npm run dev' 5173
block week
session $P 'look http://localhost:5173/ --clock 2026-10-21T10:00'
block week-back
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Previous week' --text header"
bg_stop pl
snapshot
