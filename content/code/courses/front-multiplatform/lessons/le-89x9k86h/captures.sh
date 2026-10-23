#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of front-multiplatform, as a script
# that produces them. The output is not committed: lab/fill.py pastes each
# block into the fence that holds it, and `fill.py --check` holds them equal.
#
#   sudo bash captures.sh > out.txt
#
# It needs lab.sh's machine, and starts from no ~/planner. The planner's files
# are taken from the-planner.md and look.mjs from looking-at-it.md by
# lab/extract.py, so the program each transcript ran is the one the lesson
# prints.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - git knows ana's name and address, as the `git` course has the student
#     set them; the commit carries a fixed date so its hash repeats.
#   - `npm run dev` runs in the background for "look"; the lesson has the
#     student run it in a terminal of its own, and does not quote its banner,
#     which draws with a character the interface has no glyph for.
#   - The browser: see lab.sh. "no-browser" unsets PLAYWRIGHT_BROWSERS_PATH, so
#     Playwright looks where it looks on a student's machine, which is empty.
#   - "type-error" changes one line of src/planner.ts by an exact replacement,
#     builds, and puts the line back.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
P=/home/ana/planner
LAB as 'rm -rf ~/planner; git config --global user.name "Ana Lima"; git config --global user.email ana@example.org; git config --global init.defaultBranch main'

block versions
run /home/ana 'node --version'
run /home/ana 'npm --version'
run /home/ana 'git --version'

block create
run /home/ana 'npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive | tail -n 6'
run /home/ana 'ls -A planner planner/src'

block install
run /home/ana 'cd planner'
run $P 'rm -r src public'
run $P 'npm install -E -D vite@8.3.5 typescript@6.0.3'
run $P 'cat package.json'
for f in src/planner.ts src/view.ts src/main.ts index.html public/courses.json; do
  put the-planner.md $f $P/$f
done

block build
run $P 'npm run build'

block git
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 09:00:00 -0300'"
run $P 'git init -q'
run $P 'git add .'
run $P 'git commit -q -m "The study planner, as lesson 1 gives it"'
run $P 'git log --oneline'
RUNENV=

serve $P 5173 'npm run dev'

block playwright
put looking-at-it.md look.mjs $P/look.mjs
run $P 'npm install -E -D playwright@1.63.0'

block look
run $P "node look.mjs 'http://localhost:5173/?today=2026-10-21'"
run $P "node look.mjs 'http://localhost:5173/?today=2026-10-21' --click Statistics --fill Date=2026-10-23 --fill Minutes=25 --click 'Add session'"

block second-dev
run $P 'timeout 5 npm run dev 2>&1 | head -n 6'

block no-server
unserve
run $P "node look.mjs 'http://localhost:5173/?today=2026-10-21' 2>&1 | head -n 8"

block no-browser
RUNENV='unset PLAYWRIGHT_BROWSERS_PATH'
serve $P 5173 'npm run dev'
run $P "node look.mjs 'http://localhost:5173/?today=2026-10-21' 2>&1 | head -n 5"
RUNENV=
unserve

block type-error
LAB as "cd ~/planner && sed -i 's/const id = \`s\${plan.sessions.length + 1}\`;/const id = plan.sessions.length + 1;/' src/planner.ts"
run $P 'npm run build'
LAB as 'cd ~/planner && git checkout -q src/planner.ts'
save_as 1
