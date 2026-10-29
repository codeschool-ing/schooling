#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l10.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l10.txt; done
#
# Starts from the planner and the sandbox as lesson 9 left them. Every demo,
# composable and file of the planner is taken out of the section that shows
# it; the two notes files are the two json fences of use-fetch.md, in order.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="extracting:TwoWeeks conventions:Conventions use-fetch:FetchDemo lifecycle-inside:TickerUser lifecycle-inside:LifecycleInside"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown extracting.md src/demos/useWeek.js $S/src/demos/useWeek.js
  shown conventions.md src/demos/useHours.js $S/src/demos/useHours.js
  shown use-fetch.md src/demos/useFetchJson.js $S/src/demos/useFetchJson.js
  shown lifecycle-inside.md src/demos/useTicker.js $S/src/demos/useTicker.js
  local n
  for n in 0:statistics 1:spanish; do
    python3 -c "import re,sys;print(re.findall(r'^\`\`\`json\n(.*?)^\`\`\`', open('use-fetch.md').read(), re.S|re.M)[${n%%:*}], end='')" |
      bash "$LAB_SH" script "mkdir -p ~/vue/sandbox/public/notes && cat > ~/vue/sandbox/public/notes/${n#*:}.json"
  done
  shown in-the-planner.md src/composables/useToday.js $P/src/composables/useToday.js
  shown in-the-planner.md src/composables/usePlannerData.js $P/src/composables/usePlannerData.js
  shown in-the-planner.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-xmqe6tmh
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block weeks
look_demo TwoWeeks "--do 'click button'"
block conventions
look_demo Conventions "--do 'click button'"
block fetch-1
look_demo FetchDemo
block fetch-2
look_demo FetchDemo "--do 'click #spanish'"
block fetch-3
look_demo FetchDemo "--do 'click #nope'"
block inside
look_demo LifecycleInside "--do 'wait 300' --do 'click #remove' --do 'click #late' --text -"
bg_stop sb

dev pl $P 'npm run dev' 5173
block planner
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text(\"Guitar\") input' --do 'goto /'"
bg_stop pl
snapshot
