#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l2.txt
#   for f in *.md; do python3 ../../lab/fill.py $f /tmp/l2.txt; done
#
# It starts from the project as lesson 1 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py; "a second terminal"
# is the development server started in the background, and what it printed
# is shown where the lesson shows that terminal.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

bg_stop dev
shown runs-once.md 'src/lib/Counter.svelte#1' '~/planner/src/lib/Counter.svelte'
shown runs-once.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
bg dev '~/planner' 'npm run dev'
wait_port 5173
sleep 1
block look-once
session '~/planner' "look http://localhost:5173/ --console --click 'Add 30 minutes' --click 'Add 30 minutes' --click 'Add 30 minutes'"
block dev-once
bg_show dev

shown runs-once.md 'src/lib/Counter.svelte#2' '~/planner/src/lib/Counter.svelte'
sleep 1
block look-hours
session '~/planner' "look http://localhost:5173/ --click 'Add 30 minutes' --click 'Add 30 minutes'"
block dev-hours
bg_show dev

shown signals.md src/lib/Counter.svelte '~/planner/src/lib/Counter.svelte'
sleep 1
block look-goal
session '~/planner' "look http://localhost:5173/ --console --click 'Raise the goal' --click 'Add 30 minutes'"

shown one-mutation.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block look-mutations
session '~/planner' "look http://localhost:5173/ --console --click 'Add 30 minutes' --click 'Add 30 minutes' --click 'Raise the goal'"

# As the lesson says: the page goes back to the version without the observer.
shown runs-once.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
quiet '~/planner' 'git add -A && git commit -qm "Lesson 2: the counter with a goal, and probes"'
