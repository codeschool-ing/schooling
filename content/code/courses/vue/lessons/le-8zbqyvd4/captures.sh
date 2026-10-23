#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l11.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l11.txt; done
#
# Starts from the sandbox as lesson 10 left it (useWeek.js is lesson 10's).
# Every demo is taken out of the section that shows it. The planner does not
# change in this lesson.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
DEMOS="same-component:OptionsCard same-component:CompositionCard same-component:TwoApis this:ThisTrap lifecycle-names:OptionsLifecycle mixins:Mixins mixing:Mixing"

files() {
  local d
  for d in $DEMOS; do shown ${d%%:*}.md src/demos/${d#*:}.vue $S/src/demos/${d#*:}.vue; done
  shown mixins.md src/demos/labelMixin.js $S/src/demos/labelMixin.js
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-8ken24xt
files
dev sb $S 'npm run dev' 5173
look_demo() { local d=$1; shift; session $S "look 'http://localhost:5173/?demo=$d'${*:+ $*}"; }
block two
look_demo TwoApis "--do 'click button'"
block this
look_demo ThisTrap "--do 'click #longer' --do 'click #shorter'"
block lifecycle
look_demo OptionsLifecycle "--do 'click button' --text -"
block mixins
look_demo Mixins
block mixing
look_demo Mixing "--do 'click button' --do 'click button'"
bg_stop sb
snapshot
