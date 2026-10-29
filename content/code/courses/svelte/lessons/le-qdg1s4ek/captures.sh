#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l9.txt
#   F="python3 ../../lab/fill.py"
#   $F transitions.md /tmp/l9.txt --blocks slide-now,slide-later,slide-empty
#   $F flip.md /tmp/l9.txt --blocks flip-add
#   $F tweens.md /tmp/l9.txt --blocks tween-0,tween-100,tween-200,tween-600
#   $F custom-transition.md /tmp/l9.txt --blocks flash
#   $F reduced-motion.md /tmp/l9.txt --blocks rm-before,rm-after,rm-tween
#
# It starts from the project as lesson 8 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; the lines the prose
# tells her to change in a file are changed by `replace` and `put` below,
# with the text the lesson shows. A `look` with --wait 0 prints the page as
# soon as the action is done, so it catches animations still running.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 8
PL=/home/ana/planner/src/lib/Planner.svelte
WT=/home/ana/planner/src/lib/WeekTotal.svelte

fence() { python3 -c 'import re,sys; b=re.findall(r"^```[a-z-]*\n(.*?)^```$", open(sys.argv[1]).read(), re.S|re.M); sys.stdout.write(b[int(sys.argv[2])-1])' "$1" "$2"; }
indent() { sed 's/^\(.\)/\t\1/'; }
replace() { python3 -c 'import sys; f,o,n=sys.argv[1:]; t=open(f).read(); assert t.count(o)==1,o; open(f,"w").write(t.replace(o,n))' "$@"; }

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown transitions.md src/lib/List.svelte '~/planner/src/lib/List.svelte'
sleep 1
block slide-now
session '~/planner' "look http://localhost:5173/ --click 'Previous week'"
block slide-later
session '~/planner' "look http://localhost:5173/ --click 'Previous week' --wait 500"
block slide-empty
session '~/planner' "look http://localhost:5173/ --click 'Next week'"

replace $PL $'\tlet ofCourse = $derived(thisWeek.filter((s) => s.course === selected));\n' "$(fence flip.md 1 | indent)"$'\n'
shown flip.md src/lib/List.svelte '~/planner/src/lib/List.svelte'
sleep 1
block flip-add
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter"

replace $PL $'\timport { untrack } from \'svelte\';\n' $'\timport { untrack } from \'svelte\';\n'"$(fence tweens.md 1 | indent)"$'\n'
replace $PL $'reduce((sum, s) => sum + s.minutes, 0));\n\tlet byDay' $'reduce((sum, s) => sum + s.minutes, 0));\n'"$(fence tweens.md 2 | indent)"$'\n\tlet byDay'
replace $PL $'\t<p>{doneMinutes} of {total} minutes done.</p>\n' "$(fence tweens.md 3 | indent)"$'\n'
sleep 1
for w in 0 100 200 600; do
  block tween-$w
  session '~/planner' "look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait $w"
done

shown custom-transition.md src/lib/flash.js '~/planner/src/lib/flash.js'
shown custom-transition.md src/lib/WeekTotal.svelte '~/planner/src/lib/WeekTotal.svelte'
sleep 1
block flash
session '~/planner' "look http://localhost:5173/ --fill 'Date=2026-10-21' --press Enter"

block rm-before
session '~/planner' "look http://localhost:5173/ --reduce-motion --click 'Previous week'"
shown reduced-motion.md src/lib/List.svelte '~/planner/src/lib/List.svelte'
replace $PL "import { Tween } from 'svelte/motion';" "import { Tween, prefersReducedMotion } from 'svelte/motion';"
replace $PL $'\tconst shownDone = Tween.of(() => doneMinutes, { duration: 400 });\n' "$(fence reduced-motion.md 3 | indent)"$'\n'
replace $WT $'\timport { flash } from \'#lib/flash.js\';\n' $'\timport { flash } from \'#lib/flash.js\';\n\timport { prefersReducedMotion } from \'svelte/motion\';\n'
replace $WT '<p in:flash>' '<p in:flash={{ duration: prefersReducedMotion.current ? 0 : 600 }}>'
sleep 1
block rm-after
session '~/planner' "look http://localhost:5173/ --reduce-motion --click 'Previous week'"
block rm-tween
session '~/planner' "look http://localhost:5173/ --reduce-motion --check '24 Oct 2026, 60 min' --wait 0"
done_lesson 9 "transitions, flip, a tween and a flash, all of them reduced on request"
