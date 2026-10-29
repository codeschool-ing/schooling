#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l14.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l14.txt; done
#
# Starts from the planner and the sandbox as lesson 13 left them. Every demo
# and whole file is taken out of the section that shows it; the store and
# HomeView get the lines submitting.md and session-form.md show, applied with
# python as a person would edit them. look's `select` action is lesson 1's.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="binding-inputs:Fields modifiers:Modifiers the-contract:FormField the-contract:FieldContract"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown session-form.md src/components/FormField.vue $P/src/components/FormField.vue
  shown session-form.md src/components/SessionForm.vue $P/src/components/SessionForm.vue
  bash "$LAB_SH" script "cd ~/vue/planner && python3 -" <<'PY'
p = 'src/stores/planner.js'; s = open(p).read()
if 'function add(' not in s:
    s = s.replace("import { toggleDone } from '../planner.js'", "import { toggleDone, addSession } from '../planner.js'")
    s = s.replace("    sessions.value = toggleDone(sessions.value, id)\n  }\n", "    sessions.value = toggleDone(sessions.value, id)\n  }\n\n  function add(session) {\n    sessions.value = addSession(sessions.value, session)\n  }\n")
    s = s.replace("hasCourse, load, toggle }", "hasCourse, load, toggle, add }")
    open(p, 'w').write(s)
p = 'src/views/HomeView.vue'; s = open(p).read()
if 'SessionForm' not in s:
    s = s.replace("import PlannerPanel from '../components/PlannerPanel.vue'\n", "import PlannerPanel from '../components/PlannerPanel.vue'\nimport SessionForm from '../components/SessionForm.vue'\n")
    s = s.replace("    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>\n  </PlannerPanel>\n", "    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>\n  </PlannerPanel>\n  <PlannerPanel title=\"Add a session\">\n    <SessionForm :date=\"today\" />\n  </PlannerPanel>\n")
    open(p, 'w').write(s)
PY
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-gpm9et6m
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block fields
look_demo Fields "--do 'fill #date 2026-10-30' --do 'fill #minutes 45' --do 'check #practice' --do 'fill #note verbs' --text '#app'"
block mod-1
look_demo Modifiers "--do 'fill #plain  verbs ' --do 'fill #trimmed  verbs ' --do 'fill #number 45' --do 'fill #lazy verbs' --text '#out'"
block mod-2
look_demo Modifiers "--do 'fill #lazy verbs' --do 'press Tab' --text '#out'"
block contract-1
look_demo FieldContract "--html '.field' --text '#value'"
block contract-2
look_demo FieldContract "--do 'fill input[step] 1.5' --text '#value'"
bg_stop sb

dev pl $P 'npm run dev' 5173
block errors
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'fill input[type=number] 500' --do 'click text=Add the session' --html form --text -"
block add
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'select select guitar' --do 'fill input[type=date] 2026-10-24' --do 'fill input[type=number] 25' --do 'click text=Add the session' --text main"
block empty
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Add the session' --text form"
bg_stop pl
snapshot
