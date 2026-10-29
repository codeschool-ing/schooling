#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l6.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l6.txt; done
#
# Starts from the planner and the sandbox as lesson 5 left them. Every demo
# and every file of the planner is taken out of the section that shows it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="props:GoalBar props:PropsBasics one-way:Counter one-way:OneWay emits:DoneButton emits:Emits the-contract:Fallthrough define-model:MinutesField define-model:ModelDemo"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown planner-components.md src/components/CourseCard.vue $P/src/components/CourseCard.vue
  shown planner-components.md src/components/SessionRow.vue $P/src/components/SessionRow.vue
  shown planner-components.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-b7wsvk41
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block props
look_demo PropsBasics
block one-way
look_demo OneWay "--do 'click #number' --do 'click #object'"
block emits
look_demo Emits "--do 'click .done' --do 'click .undo' --do 'click :nth-match(.done, 2)'"
block fallthrough
look_demo Fallthrough "--html p --text -"
block model-click
look_demo ModelDemo "--do 'click text=+15' --text '#parent'"
block model-fill
look_demo ModelDemo "--do 'fill input 100' --text '#parent'"
bg_stop sb

dev pl $P 'npm run dev' 5173
block planner
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text(\"Guitar\") input' --text main"
bg_stop pl
snapshot
