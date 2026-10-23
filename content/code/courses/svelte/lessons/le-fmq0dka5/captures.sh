#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l3.txt
#   for f in the-data state derived deep-state props; do python3 ../../lab/fill.py $f.md /tmp/l3.txt; done
#   python3 ../../lab/fill.py effect.md /tmp/l3.txt --blocks effect
#
# It starts from the project as lesson 2 left it, with the development server
# running. STAGED: the files ana writes, taken out of the lesson's .md by
# lab/shown.py, one version per section, in the order the sections give them.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 2

if ! (exec 3<>/dev/tcp/127.0.0.1/5173) 2>/dev/null; then bg dev '~/planner' 'npm run dev'; wait_port 5173; fi

shown the-data.md src/lib/planner.json '~/planner/src/lib/planner.json'
shown the-data.md src/lib/week.js '~/planner/src/lib/week.js'
block week-js
session '~/planner' "node -e \"import('./src/lib/week.js').then((w) => console.log(w.mondayOf('2026-10-24'), w.format('2026-10-19'), w.inWeek('2026-10-25', '2026-10-19')))\""

shown state.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block state
session '~/planner' 'look http://localhost:5173/'
block state-nav
session '~/planner' "look http://localhost:5173/ --click 'Next week' --click 'Previous week' --click 'Previous week'"

shown derived.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block derived
session '~/planner' "look http://localhost:5173/ --click 'Previous week'"

shown deep-state.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block deep
session '~/planner' "look http://localhost:5173/ --console --click 'Add 30 minutes on 19 Oct 2026' --click '24 Oct 2026, 60 min'"

shown effect.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block effect
session '~/planner' "look http://localhost:5173/ --click 'Previous week'"

shown props.md src/lib/WeekTotal.svelte '~/planner/src/lib/WeekTotal.svelte'
shown props.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block props
session '~/planner' "look http://localhost:5173/ --click 'Guitar'"
done_lesson 3 "the planner page, with runes"
