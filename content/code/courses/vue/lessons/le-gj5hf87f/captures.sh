#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l4.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l4.txt; done
#
# Starts from the planner and the sandbox as lesson 3 left them. Every demo
# and every file of the planner is taken out of the section that shows it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="watch:WatchSources deep-and-once:DeepAndOnce watch-effect:EffectTracking timing:FlushTiming cleanup:StaleAnswer stopping:Listener stopping:StopWatching"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown stopping.md src/demos/clock.js $S/src/demos/clock.js
  shown saving.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-m1vycz2b
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block sources
look_demo WatchSources "--do 'click #longer' --do 'click #longer' --do 'click #guitar' --text -"
block deep
look_demo DeepAndOnce "--do 'click #push' --do 'click #replace' --do 'click #push' --text -"
block effect
look_demo EffectTracking "--do 'click #minutes' --do 'click #note' --do 'click #course' --text -"
block flush
look_demo FlushTiming "--do 'click button' --text -"
block stale
look_demo StaleAnswer "--do 'click #stats' --do 'click #spanish' --do 'wait 800'"
block stop
look_demo StopWatching "--do 'click #tick' --do 'click #tick' --do 'click #remove' --do 'click #tick'"
bg_stop sb

dev pl $P 'npm run dev' 5173
block saving
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'goto /' --text header"
bg_stop pl
snapshot
