#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l13.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l13.txt; done
#
# Starts from the planner and the sandbox as lesson 12 left them. Installs
# pinia 4.1.0 from the npm registry, in both. Every demo and every whole file
# is taken out of the section that shows it; the views and the router get the
# lines planner-store.md shows, applied with python as a person would edit
# them, and keys.js and usePlannerData.js are deleted as it says.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="why-a-store:TallyBox why-a-store:WhyAStore options-store:OptionsStore store-to-refs:LostRefs subscribe:Subscribe"

files() {
  quiet $S 'grep -q pinia package.json || npm install --silent --save-exact pinia@4.1.0'
  quiet $P 'grep -q pinia package.json || npm install --silent --save-exact pinia@4.1.0'
  shown why-a-store.md src/main.js $S/src/main.js
  shown why-a-store.md src/demos/tally.js $S/src/demos/tally.js
  shown options-store.md src/demos/sessionsStore.js $S/src/demos/sessionsStore.js
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown define-store.md src/stores/planner.js $P/src/stores/planner.js
  shown planner-store.md src/main.js $P/src/main.js
  shown planner-store.md src/App.vue $P/src/App.vue
  shown planner-store.md src/components/SessionRow.vue $P/src/components/SessionRow.vue
  bash "$LAB_SH" script "cd ~/vue/planner && python3 -" <<'PY'
import re
src = 'src/'
r = open(src + 'router.js').read()
if 'usePlannerStore' not in r:
    r = r.replace("import NotFound from './views/NotFound.vue'\n", "import NotFound from './views/NotFound.vue'\nimport { usePlannerStore } from './stores/planner.js'\n")
    r = r[:r.index("// Asks the data file")] + r[r.index("const routes"):]
    r = r.replace("      if (!(await courseExists(to.params.id))) {", "      const planner = usePlannerStore()\n      await planner.load()\n      if (!planner.hasCourse(to.params.id)) {")
    open(src + 'router.js', 'w').write(r)
for name, today in (('HomeView', True), ('CourseView', False), ('CourseWeek', True), ('CourseAll', True)):
    p = src + 'views/' + name + '.vue'
    s = open(p).read()
    if 'plannerKey' not in s:
        continue
    s = s.replace("import { plannerKey } from '../keys.js'\n", "import { storeToRefs } from 'pinia'\nimport { usePlannerStore } from '../stores/planner.js'\n" + ("import { useToday } from '../composables/useToday.js'\n" if today else ""))
    s = s.replace("inject, ", "").replace(", inject", "")
    def repl(m):
        ns = [n.strip() for n in m.group(1).split(',')]
        out = "const planner = usePlannerStore()\n"
        out += "const { " + ", ".join(n for n in ns if n in ('courses', 'sessions')) + " } = storeToRefs(planner)\n"
        if 'toggle' in ns: out += "const { toggle } = planner\n"
        if 'today' in ns: out += "const today = useToday()\n"
        return out
    s = re.sub(r"const \{ ([^}]*) \} = inject\(plannerKey\)\n", repl, s)
    open(p, 'w').write(s)
PY
  quiet $P 'rm -f src/keys.js src/composables/usePlannerData.js'
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-399ctrsd
block sandbox-pinia
session $S 'npm install --save-exact pinia@4.1.0'
block planner-pinia
session $P 'npm install --save-exact pinia@4.1.0'
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block why
look_demo WhyAStore "--do 'click #add-week' --do 'click #add-week' --do 'click #add-course'"
block options-1
look_demo OptionsStore "--do 'click #toggle' --text '#totals'"
block options-2
look_demo OptionsStore "--do 'click #patch' --do 'click #reset' --text '#totals'"
block refs
look_demo LostRefs "--do 'click button'"
block subscribe
look_demo Subscribe "--do 'click #toggle' --do 'click #patch' --do 'click #direct' --text -"
bg_stop sb

dev pl $P 'npm run dev' 5173
block planner
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --do 'check label:has-text(\"23 October\") input' --do 'click text=Study planner' --text main --network"
bg_stop pl
quiet $P 'grep -rn "keys.js\|usePlannerData\|inject(" src || true'
snapshot
