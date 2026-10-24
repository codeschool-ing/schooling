#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l9.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l9.txt; done
#
# Starts from the planner and the sandbox as lesson 8 left them. Every demo
# and SessionRow.vue are taken out of the section that shows them. App.vue
# gets the lines cleaning-up.md shows, applied with python as a person would
# paste them in. The timings of the leaking demo differ from run to run.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="the-hooks:Lifecycle the-hooks:Hooks order:Child order:Order template-refs:TemplateRefs cleaning-up:Ticker cleaning-up:Leak setup-or-mounted:SetupOrMounted keep-alive:Draft keep-alive:KeptAlive"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown cleaning-up.md src/components/SessionRow.vue $P/src/components/SessionRow.vue
  local block
  block=$(python3 - cleaning-up.md <<'PY'
import re, sys
t = open(sys.argv[1]).read()
print(re.search(r"```javascript\n(const today = .*?)```", t, re.S).group(1), end="")
PY
)
  bash "$LAB_SH" script "cd ~/vue/planner && python3 - src/App.vue" <<PY
import sys
p = sys.argv[1]; s = open(p).read()
if 'const today' not in s:
    s = s.replace("import { ref, computed, watch, provide } from 'vue'", "import { ref, computed, watch, provide, onMounted, onUnmounted } from 'vue'")
    s = s.replace("import { weekStart, addDays,", "import { isoDate, weekStart, addDays,")
    s = s.replace("const monday = ref(weekStart(new Date()))\n", "const monday = ref(weekStart(new Date()))\n\n" + """$block""")
    s = s.replace('          :session="session"\n          @toggle', '          :session="session"\n          :today="session.date === today"\n          @toggle')
    open(p, 'w').write(s)
PY
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-snjrwkmr
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block hooks
look_demo Hooks "--do 'click #more' --do 'click #remove' --text -"
block order
look_demo Order "--do 'click button' --text -"
block refs
look_demo TemplateRefs "--do 'click button' --text -"
block leak
look_demo Leak "--do 'wait 250' --do 'click button' --do 'wait 250' --text -"
block setup
look_demo SetupOrMounted "--text -"
block keep
look_demo KeptAlive "--do 'fill input verbs' --do 'click #spanish' --do 'click #stats'"
bg_stop sb

dev pl $P 'npm run dev' 5173
block today
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --text 'main section:nth-child(2) ul'"
bg_stop pl
snapshot
