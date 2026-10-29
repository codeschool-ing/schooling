#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l8.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l8.txt; done
#
# Starts from the planner and the sandbox as lesson 7 left them. Every demo
# and every file of the planner is taken out of the section that shows it,
# except App.vue, whose two new lines what-it-costs.md shows and which the
# capture applies to lesson 7's App.vue with sed, as a person would edit it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="prop-drilling:DrillLeaf prop-drilling:DrillMiddle prop-drilling:PropDrilling provide-inject:InjectLeaf provide-inject:InjectMiddle provide-inject:ProvideInject reactive-provide:TotalBadge reactive-provide:ReactiveProvide missing-provider:Orphan"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown provide-inject.md src/demos/keys.js $S/src/demos/keys.js
  shown what-it-costs.md src/keys.js $P/src/keys.js
  shown what-it-costs.md src/components/SessionRow.vue $P/src/components/SessionRow.vue
  quiet $P "grep -q titlesKey src/App.vue || sed -i \
    -e \"s/import { ref, computed, watch } from 'vue'/import { ref, computed, watch, provide } from 'vue'/\" \
    -e \"s|^import { weekStart,|import { titlesKey } from './keys.js'\nimport { weekStart,|\" \
    -e '/^const titles = computed/a provide(titlesKey, titles)' \
    -e '/:title=\"titles\[session.course\]\"/d' src/App.vue"
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-zagre0mh
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block drilling
look_demo PropDrilling
block provided
look_demo ProvideInject
block reactive
look_demo ReactiveProvide "--do 'click #add' --do 'click #cheat'"
block orphan
look_demo Orphan
block symbols
session $S "node -e \"console.log(Symbol('unit') === Symbol('unit'), 'unit' === 'unit')\""
bg_stop sb

dev pl $P 'npm run dev' 5173
block titles
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --text 'main section:nth-child(2) ul'"
bg_stop pl
snapshot
