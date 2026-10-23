#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l5.txt
#   for f in splitting binding-elements props-are-not-yours bindable styles; do
#     python3 ../../lab/fill.py $f.md /tmp/l5.txt; done
#
# It starts from the project as lesson 4 committed it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; the one-line edits
# the prose describes (a line of the page swapped, a rule added to a style
# and taken out again) are made by `swap` and `sed` below, with exactly the
# text the prose gives. The development server is started again before the
# unused-selector step, so that its terminal holds only that warning.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
P=/home/ana/planner/src/routes/+page.svelte
L=/home/ana/planner/src/lib

# swap PREFIX LINE: replace the page's line that starts with PREFIX by LINE.
swap() {
  python3 - "$P" "$1" "$2" <<'PY'
import sys
p, prefix, line = sys.argv[1:]
lines = open(p).read().split("\n")
hits = [i for i, l in enumerate(lines) if l.strip().startswith(prefix)]
assert len(hits) == 1, (prefix, hits)
lines[hits[0]] = "\t" + line
open(p, "w").write("\n".join(lines))
PY
}

quiet '~/planner' 'git reset -q --hard && git clean -qfd'
bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown splitting.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'
shown splitting.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block split
session '~/planner' "look http://localhost:5173/ --click 'Spanish'"

shown binding-elements.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
shown binding-elements.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block bind
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --fill 'Minutes=45' --click 'Add session' --check '24 Oct 2026, 60 min'"

shown props-are-not-yours.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
swap '<AddSession' '<AddSession {sessions} course={selected} />'
sleep 1
block mutate
session '~/planner' "look http://localhost:5173/ --console --fill 'Date=2026-10-21' --click 'Add session' --fill 'Date=2026-10-24' --click 'Add session'"
shown binding-elements.md src/lib/AddSession.svelte '~/planner/src/lib/AddSession.svelte'
swap '<AddSession' '<AddSession onadd={add} />'

shown bindable.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'
swap '<CourseList' '<CourseList courses={data.courses} minutes={byCourse} bind:selected />'
sleep 1
block bindable
session '~/planner' "look http://localhost:5173/ --click 'Guitar'"
# As the lesson says: take $bindable out of CourseList, look, put it back.
sed -i 's/let { courses, minutes, selected = \$bindable() } = \$props();/let { courses, minutes, selected } = $props();/' $L/CourseList.svelte
sleep 1
block not-bindable
session '~/planner' "look http://localhost:5173/ --console --click 'Guitar'"
shown bindable.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'

shown styles.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'
shown styles.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block classes
session '~/planner' "curl -s http://localhost:5173/ | grep -o 'class=\"[^\"]*\"' | sort | uniq -c"

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173
sed -i 's|^</style>$|\n\t.selected { font-style: italic; }\n</style>|' $L/CourseList.svelte
session '~/planner' 'look http://localhost:5173/' > /dev/null
sleep 1
block unused
bg_show dev
shown styles.md src/lib/CourseList.svelte '~/planner/src/lib/CourseList.svelte'
quiet '~/planner' 'git add -A && git commit -qm "Lesson 5: CourseList, AddSession, bindings and styles"'
