#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of mobile-fundamentals, as a script
# that produces them. lab/fill.py pastes each block into the fence that holds
# it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - ~/planner holds lesson 1's package.json and lesson 18's tokens.ts, each
#     taken out of the lesson that shows it; nothing else from earlier lessons
#     is needed here.
#   - contrast.ts and targets.ts are taken out of this lesson's contrast.md
#     and targets.md.
#   - "contrast-777" and "contrast-fixed" change the light `muted` colour in
#     tokens.ts by an exact replacement, as the lesson tells the student to.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

put ../le-55jmmbqr/the-planner.md package.json $P/package.json
put ../le-gq5mpmdf/tokens.md tokens.ts $P/tokens.ts
put targets.md targets.ts $P/targets.ts
put contrast.md contrast.ts $P/contrast.ts

swap() { # swap FILE OLD NEW: replace one exact string in ana's file
  python3 - "$H${1#/home/ana}" "$2" "$3" <<'PY'
import sys
p, a, b = sys.argv[1:]
s = open(p).read()
assert s.count(a) == 1, (p, a)
open(p, "w").write(s.replace(a, b))
PY
}

block targets
run $P 'node targets.ts'

block contrast
run $P 'node contrast.ts; echo "exit $?"'

block contrast-777
swap $P/tokens.ts 'muted: "#8A8A8A"' 'muted: "#777777"'
run $P 'node contrast.ts; echo "exit $?"'

block contrast-fixed
swap $P/tokens.ts 'muted: "#777777"' 'muted: "#767676"'
run $P 'node contrast.ts; echo "exit $?"'
