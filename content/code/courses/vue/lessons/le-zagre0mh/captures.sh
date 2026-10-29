#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l7.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l7.txt; done
#
# Starts from the planner and the sandbox as lesson 6 left them. Every demo
# and every file of the planner is taken out of the section that shows it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="default-slot:InfoCard default-slot:DefaultSlot named-slots:TitledPanel named-slots:NamedSlots scoped-slots:SessionTable scoped-slots:ScopedSlots render-props:WeekPager render-props:Renderless"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown panel.md src/components/PlannerPanel.vue $P/src/components/PlannerPanel.vue
  shown panel.md src/components/CourseCard.vue $P/src/components/CourseCard.vue
  shown panel.md src/main.css $P/src/main.css
  shown panel.md src/main.js $P/src/main.js
  shown panel.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-sxzxb7zh
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block default
look_demo DefaultSlot
block named
look_demo NamedSlots "--html '#app' --text -"
block scoped
look_demo ScopedSlots
block renderless
look_demo Renderless "--do 'click #on' --do 'click #on' --do 'click #back'"
bg_stop sb

dev pl $P 'npm run dev' 5173
block panel
session $P 'look http://localhost:5173/ --clock 2026-10-21T10:00'
block panel-empty
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --text 'main section:nth-child(2)'"
bg_stop pl
snapshot
