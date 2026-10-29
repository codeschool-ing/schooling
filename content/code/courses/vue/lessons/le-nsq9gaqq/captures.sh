#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l2.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l2.txt; done
#
# Starts from the planner as lesson 1 left it. Makes the sandbox the way
# two-models.md says, and every demo and every file of the planner is taken
# out of the section that shows it. Dev servers run "in a second terminal"
# and are stopped afterwards.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="two-models:RunsOnce ref:RefBasics ref:Unwrapping reactive:ReactiveProxy losing-it:LostReactivity the-update-queue:UpdateQueue"

sandbox() {
  quiet '~/vue' 'rm -rf sandbox && npm create vue@3.24.0 -- --prettier --bare sandbox > /dev/null &&
    cd sandbox && cp ../planner/package.json ../planner/package-lock.json ../planner/vite.config.js . &&
    npm pkg set name=sandbox && npm install --silent && mkdir -p src/demos'
}
files() {
  [ -d /home/ana/vue/sandbox ] || sandbox
  shown two-models.md src/main.js $S/src/main.js
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown loading-the-data.md public/courses.json $P/public/courses.json
  shown loading-the-data.md src/App.vue $P/src/App.vue
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-qr5h8fwt
quiet '~/vue' 'rm -rf sandbox'
block sandbox
session '~/vue' 'npm create vue@3.24.0 -- --prettier --bare sandbox > /dev/null' 'cd sandbox' \
  'cp ../planner/package.json ../planner/package-lock.json ../planner/vite.config.js .' \
  'npm pkg set name=sandbox' 'npm install' 'mkdir src/demos'
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block runs-once
look_demo RunsOnce "--do 'click button' --do 'click button' --do 'click button'"
block ref-basics
look_demo RefBasics "--do 'click button'"
block unwrapping
look_demo Unwrapping
block reactive-proxy
look_demo ReactiveProxy "--do 'click #proxy' --do 'click #raw'"
block reactive-proxy-3
look_demo ReactiveProxy "--do 'click #proxy' --do 'click #raw' --do 'click #proxy'"
block lost
look_demo LostReactivity "--do 'click button'"
block queue
look_demo UpdateQueue "--do 'click button'"
bg_stop sb

dev pl $P 'npm run dev' 5173
block planner-loads
session $P 'look http://localhost:5173/ --network'
block planner-missing
session $P 'mv public/courses.json /tmp/courses.json' 'look http://localhost:5173/' \
  'curl -si http://localhost:5173/courses.json | head -n 3' 'mv /tmp/courses.json public/'
bg_stop pl
snapshot
