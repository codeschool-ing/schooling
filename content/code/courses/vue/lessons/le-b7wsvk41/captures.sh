#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l5.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l5.txt; done
#
# Starts from the planner and the sandbox as lesson 4 left them. Every demo
# and every file of the planner is taken out of the section that shows it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="v-if-and-v-show:Noisy v-if-and-v-show:IfAndShow v-for:ForLoops v-for:IfInsideFor the-key:StarRow the-key:KeyMatters v-model:ModelBasics bind-and-on:BindAndOn custom-directives:FocusDirective"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown session-list.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-gj5hf87f
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block if-show
look_demo IfAndShow "--do 'click button' --do 'click button' --do 'click button' --html '#panels' --text -"
block for
look_demo ForLoops
block if-in-for
look_demo IfInsideFor
block key
look_demo KeyMatters "--do 'click #by-index button' --do 'click #by-id button' --do 'click #remove'"
block model
look_demo ModelBasics "--do 'fill #note verbs' --do 'check #done' --do 'check #exercises' --text '#state'"
block bind
look_demo BindAndOn "--do 'click #done' --do 'fill #minutes 60' --do 'press Enter' --html p --text -"
block focus
look_demo FocusDirective "--text -"
bg_stop sb

dev pl $P 'npm run dev' 5173
block list
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text(\"Guitar\") input' --do 'goto /' --text main"
bg_stop pl
snapshot
