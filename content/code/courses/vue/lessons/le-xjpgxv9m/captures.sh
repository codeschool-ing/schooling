#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l15.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l15.txt; done
#
# Starts from the planner and the sandbox as lesson 14 left them; the notes
# files are lesson 10's, and look's --reduced-motion is lesson 1's. Every demo
# and whole file is taken out of the section that shows it; SessionForm gets
# the two lines reduced-motion.md shows, applied with python.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="teleport:TeleportDemo dialog:DialogDemo suspense:SlowCourse suspense:LoadingNote suspense:SuspenseDemo async-errors:ErrorsDemo transition:FadeDemo transition-group:ListDemo"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown reduced-motion.md src/components/PlannerDialog.vue $P/src/components/PlannerDialog.vue
  shown reduced-motion.md src/main.css $P/src/main.css
  shown reduced-motion.md src/views/HomeView.vue $P/src/views/HomeView.vue
  bash "$LAB_SH" script "cd ~/vue/planner && python3 -" <<'PY'
p = 'src/components/SessionForm.vue'; s = open(p).read()
if "defineEmits(['added'])" not in s:
    s = s.replace("const planner = usePlannerStore()\n", "const planner = usePlannerStore()\nconst emit = defineEmits(['added'])\n", 1)
    s = s.replace("  courseField.value.focus()\n}", "  courseField.value.focus()\n  emit('added', saved.value)\n}")
    open(p, 'w').write(s)
PY
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-dj9p7pp5
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block teleport
look_demo TeleportDemo "--do 'click button' --html body --text -"
block dialog
look_demo DialogDemo "--do 'click #open' --do 'press Escape' --do 'click #open' --do 'click #add' --text -"
block suspense
look_demo SuspenseDemo
block compiled
session $S "curl -s 'http://localhost:5173/src/demos/SlowCourse.vue' | grep -n withAsyncContext"
block errors
look_demo ErrorsDemo
block fade-mid
look_demo FadeDemo "--do 'click button' --html '#note' --text -"
block fade-end
look_demo FadeDemo "--do 'click button' --do 'wait 1000' --text -"
block list
look_demo ListDemo "--do 'click button' --html '#list' --text -"
block reduced
session $S "look 'http://localhost:5173/?demo=FadeDemo' --reduced-motion --do 'click button' --do 'wait 1000' --html '#note' --text -"
bg_stop sb

dev pl $P 'npm run dev' 5173
block planner
session $P "look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Add a session' --do 'select select guitar' --do 'fill input[type=date] 2026-10-24' --do 'fill input[type=number] 25' --do 'click text=Add the session' --text 'main section:nth-child(3)'"
bg_stop pl
snapshot
