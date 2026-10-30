#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of mobile-fundamentals, as a script
# that produces them. The output is not committed: lab/fill.py pastes each
# block into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js 22.22.0 in ~/.local/node, as
# lab.sh installs it, and no ~/planner. planner.ts and week.ts are taken out of
# the-planner.md, and package.json too, by lab/extract.py, so the program each
# transcript ran is the one the lesson prints.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - git knows ana's name and address, as the `git` course has the student
#     set them; the commit carries a fixed date so its hash repeats.
#   - "old-node": Node.js 22.17.0, the last 22 before type stripping was on by
#     default, is unpacked from nodejs.org's file (checked against its
#     SHA-256) into ~/old-node, to show what it says to a .ts file. A student
#     meets this when an older Node.js is the one the terminal finds first.
#   - "no-ext", "enum" and "no-type" change one line of a file by an exact
#     replacement, run it, and put the line back.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner

block versions
run /home/ana 'node --version'
run /home/ana 'npm --version'
run /home/ana 'git --version'

block mkdir
run /home/ana 'mkdir planner'
run /home/ana 'cd planner'

for f in package.json planner.ts week.ts; do put the-planner.md $f $P/$f; done

block run
run $P 'ls'
run $P 'node week.ts'

block git
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'"
run $P 'git init -q'
run $P 'git add .'
run $P 'git commit -q -m "The planner core, as lesson 1 gives it"'
run $P 'git log --oneline'
RUNENV=

# --- the failures ---
block wrong-folder
run /home/ana 'node week.ts'

OLD=node-v22.17.0-linux-x64.tar.xz
T=$(mktemp -d)
curl -fsSL -o "$T/$OLD" "https://nodejs.org/dist/v22.17.0/$OLD"
echo "325c0f1261e0c61bcae369a1274028e9cfb7ab7949c05512c5b1e630f7e80e12  $T/$OLD" | sha256sum -c --quiet
mkdir -p "$H/old-node" && tar -xJf "$T/$OLD" -C "$H/old-node" --strip-components=1 && rm -rf "$T"
chown -R ana:ana "$H/old-node"
block old-node
run $P '~/old-node/bin/node --version'
run $P '~/old-node/bin/node week.ts'
rm -rf "$H/old-node"

swap() { # swap FILE OLD NEW: replace one exact line in ana's file
  python3 - "$H${1#/home/ana}" "$2" "$3" <<'PY'
import sys
p, a, b = sys.argv[1:]
s = open(p).read()
assert s.count(a) == 1, (p, a)
open(p, "w").write(s.replace(a, b))
PY
}
block no-ext
swap $P/week.ts 'from "./planner.ts";' 'from "./planner";'
run $P 'node week.ts'
swap $P/week.ts 'from "./planner";' 'from "./planner.ts";'

block enum
swap $P/planner.ts 'export type Course = { id: string; title: string };' 'export enum Level { Beginner, Advanced }
export type Course = { id: string; title: string };'
run $P 'node week.ts'
swap $P/planner.ts 'export enum Level { Beginner, Advanced }
export type Course' 'export type Course'

block no-type
swap $P/package.json '  "private": true,
  "type": "module"' '  "private": true'
run $P 'node week.ts'
swap $P/package.json '  "private": true' '  "private": true,
  "type": "module"'

block fixed
run $P 'node week.ts'
