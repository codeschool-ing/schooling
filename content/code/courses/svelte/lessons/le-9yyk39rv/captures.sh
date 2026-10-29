#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l11.txt
#   F="python3 ../../lab/fill.py"
#   $F create-context.md /tmp/l11.txt --blocks context
#   $F missing-context.md /tmp/l11.txt --blocks missing,missing-dev
#   $F server-state.md /tmp/l11.txt --blocks leak,no-leak
#
# It starts from the project as lesson 10 left it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py. The development
# server is started again before the missing context, so that its terminal
# shows that error alone.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh
from_lesson 10

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown create-context.md context.js '~/planner/src/lib/context.js'
shown create-context.md src/lib/Status.svelte '~/planner/src/lib/Status.svelte'
shown create-context.md src/lib/Days.svelte '~/planner/src/lib/Days.svelte'
shown create-context.md src/lib/Planner.svelte '~/planner/src/lib/Planner.svelte'
sleep 1
block context
session '~/planner' "look http://localhost:5173/ --check '24 Oct 2026, 60 min' --wait 500"

bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173
shown missing-context.md src/routes/days/+page.svelte '~/planner/src/routes/days/+page.svelte'
sleep 1
block missing
session '~/planner' 'look http://localhost:5173/days'
sleep 1
block missing-dev
bg_show dev
quiet '~/planner' 'rm -r src/routes/days'

shown server-state.md 'visitor.svelte.js#1' '~/planner/src/lib/visitor.svelte.js'
shown server-state.md 'src/routes/hello/+page.svelte#1' '~/planner/src/routes/hello/+page.svelte'
sleep 1
block leak
session '~/planner' "curl -s 'http://localhost:5173/hello?name=Ana' | grep -o 'Hello[^<]*'" \
  "curl -s http://localhost:5173/hello | grep -o 'Hello[^<]*'"
shown server-state.md 'visitor.svelte.js#2' '~/planner/src/lib/visitor.svelte.js'
shown server-state.md 'src/routes/hello/+page.svelte#2' '~/planner/src/routes/hello/+page.svelte'
sleep 1
block no-leak
session '~/planner' "curl -s 'http://localhost:5173/hello?name=Ana' | grep -o 'Hello[^<]*'" \
  "curl -s http://localhost:5173/hello | grep -o 'Hello[^<]*'"
quiet '~/planner' 'rm -r src/routes/hello src/lib/visitor.svelte.js'
done_lesson 11 "the planner in context, with Status and Days"
