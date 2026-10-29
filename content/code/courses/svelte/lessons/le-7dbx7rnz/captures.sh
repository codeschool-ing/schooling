#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l10.txt
#   F="python3 ../../lab/fill.py"
#   $F store-contract.md /tmp/l10.txt --blocks clock
#   $F writable-readable-derived.md /tmp/l10.txt --blocks timer
#   $F runes-in-modules.md /tmp/l10.txt --blocks class
#
# It starts from the project as lesson 9 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 9

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown store-contract.md src/lib/timer.js '~/planner/src/lib/timer.js'
shown store-contract.md src/routes/timer/+page.svelte '~/planner/src/routes/timer/+page.svelte'
sleep 1
block clock
session '~/planner' 'look http://localhost:5173/timer --wait 2400'

shown writable-readable-derived.md src/lib/timer.js '~/planner/src/lib/timer.js'
shown writable-readable-derived.md src/routes/timer/+page.svelte '~/planner/src/routes/timer/+page.svelte'
sleep 1
block timer
session '~/planner' 'look http://localhost:5173/timer --click Start --wait 2400'

shown runes-in-modules.md src/lib/planner.svelte.js '~/planner/src/lib/planner.svelte.js'
shown runes-in-modules.md src/lib/Planner.svelte '~/planner/src/lib/Planner.svelte'
sleep 1
block class
session '~/planner' "look http://localhost:5173/ --click 'Spanish' --fill 'Date=2026-10-21' --press Enter --click 'Previous week' --wait 500"

# As the last section says: the timer goes.
quiet '~/planner' 'rm -r src/routes/timer src/lib/timer.js'
done_lesson 10 "the planner's state in a class, and a timer made of stores"
