#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l7.txt
#   for f in forms keyboard; do python3 ../../lab/fill.py $f.md /tmp/l7.txt; done
#
# It starts from the project as lesson 6 committed it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; the edits the prose
# describes in words (the preventDefault line taken out and put back, the
# course list's item made clickable and put back) are made below with the
# text the prose gives. The development server is started again before the
# accessibility warnings, so that its terminal holds only them.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
L=/home/ana/planner/src/lib

from_lesson 6
bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown forms.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
sleep 1
block enter
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter"
block required
session '~/planner' "look http://localhost:5173/ --click 'Add session'"
sed -i '/event.preventDefault();/d' $L/AddSession.svelte
sleep 1
block reload
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter"
shown forms.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173
python3 - $L/CourseList.svelte <<'PY'
import sys
p = sys.argv[1]
t = open(p).read()
old = ("\t\t<li>\n\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n"
       "\t\t\t{minutes[c.id] ?? 0} min\n\t\t</li>\n")
new = "\t\t<li onclick={() => (selected = c.id)}>{c.name} {minutes[c.id] ?? 0} min</li>\n"
assert old in t
open(p, "w").write(t.replace(old, new))
PY
session '~/planner' 'look http://localhost:5173/' > /dev/null
sleep 1
block a11y
bg_show dev
quiet '~/planner' 'git checkout -q src/lib/CourseList.svelte'

shown keyboard.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block arrow
session '~/planner' 'look http://localhost:5173/ --press ArrowLeft'
block arrow-field
session '~/planner' "look http://localhost:5173/ --fill 'Minutes=45' --press ArrowLeft"
quiet '~/planner' 'git add -A && git commit -qm "Lesson 7: a form that submits, and the week shortcuts"'
