#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l4.txt
#   for f in what-changed a-svelte-4-component reactive-statements migrating; do
#     python3 ../../lab/fill.py $f.md /tmp/l4.txt; done
#   python3 ../../lab/fill.py old-code.md /tmp/l4.txt --blocks old,old-dev,stores,stores-dev,new
#
# It starts from the project as lesson 3 committed it. The development server is
# started again at the beginning, so that its terminal holds only this
# lesson's lines, and again before each of the old-code pages, so that each
# error is shown on its own. STAGED: the files ana writes, taken out of the lesson's .md
# by lab/shown.py; the edits the prose describes in words (one line of the
# page replaced, the first line of WeekNav deleted and put back, the old/
# folder removed) are made by the small programs below, which do exactly
# what the sentence says.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 3
P=/home/ana/planner/src/routes/+page.svelte

# page LINE: the page as lesson 3 left it, with WeekNav imported and the
# paragraph of week buttons (or the WeekNav line) replaced by LINE.
page() {
  python3 - "$P" "$1" <<'PY'
import re, sys
p, line = sys.argv[1], sys.argv[2]
t = open(p).read()
if "import WeekNav" not in t:
    t = t.replace("\timport WeekTotal from '#lib/WeekTotal.svelte';\n",
                  "\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport WeekNav from '#lib/WeekNav.svelte';\n")
t, n = re.subn(r"\t<p>\n\t\t<button onclick=\{\(\) => \(week = addDays\(week, -7\)\)\}>Previous week</button>\n.*?\t</p>\n|\t<WeekNav [^\n]*\n",
               lambda m: "\t" + line + "\n", t, count=1, flags=re.S)
assert n == 1
open(p, "w").write(t)
PY
}

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown a-svelte-4-component.md src/lib/WeekNav.svelte '~/planner/src/lib/WeekNav.svelte'
page '<WeekNav {week} on:change={(event) => (week = event.detail.week)} />'
sleep 1
block legacy
session '~/planner' "look http://localhost:5173/ --click 'Next week' --click 'Previous week' --click 'Previous week'"

# As the lesson says: delete the first line, look, and put it back.
sed -i 1d /home/ana/planner/src/lib/WeekNav.svelte
sleep 1
session '~/planner' 'look http://localhost:5173/' > /dev/null
sleep 1
block legacy-error
bg_show dev
shown a-svelte-4-component.md src/lib/WeekNav.svelte '~/planner/src/lib/WeekNav.svelte'

shown reactive-statements.md src/lib/WeekNav.svelte '~/planner/src/lib/WeekNav.svelte'
sleep 1
block dollar
session '~/planner' "look http://localhost:5173/ --click 'Next week' --click 'Next week'"
shown a-svelte-4-component.md src/lib/WeekNav.svelte '~/planner/src/lib/WeekNav.svelte'

shown migrating.md migrate.mjs '~/planner/migrate.mjs'
block migrate
session '~/planner' 'node migrate.mjs src/lib/WeekNav.svelte'
shown migrating.md src/lib/WeekNav.svelte '~/planner/src/lib/WeekNav.svelte'
page '<WeekNav {week} onchange={(next) => (week = next)} />'
sleep 1
block migrated
session '~/planner' "look http://localhost:5173/ --click 'Previous week'"

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173
shown old-code.md 'src/routes/old/+page.svelte#1' '~/planner/src/routes/old/+page.svelte'
sleep 1
block old
session '~/planner' 'look http://localhost:5173/old'
sleep 1
block old-dev
bg_show dev
shown old-code.md 'src/routes/old/+page.svelte#2' '~/planner/src/routes/old/+page.svelte'
bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173
block stores
session '~/planner' 'look http://localhost:5173/old'
sleep 1
block stores-dev
bg_show dev
shown old-code.md 'src/routes/old/+page.svelte#3' '~/planner/src/routes/old/+page.svelte'
sleep 1
block new
session '~/planner' 'look http://localhost:5173/old'
quiet '~/planner' 'rm -r src/routes/old'
quiet '~/planner' 'git add -A && git commit -qm "Lesson 4: WeekNav, from Svelte 4 to Svelte 5"'
