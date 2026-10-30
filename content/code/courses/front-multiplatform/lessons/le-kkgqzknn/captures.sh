#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 10 left. The two versions of electron/main.mjs,
# electron/preload.cjs and desk.mjs are taken from the lesson by
# lab/extract.py; the edit to src/device.ts is the one preload-and-ipc.md
# shows, applied by exact replacement (python below).
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The machine has no screen, so every window opens on Xvfb, through
#     xvfb-run, which the transcripts show; running-without-a-screen.md says
#     why and what a desktop does instead.
#   - A system D-Bus runs in the machine (lab.sh), as on any Linux desktop.
#   - ~/.config/planner is removed first, so the listing shows one run's files.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 10
P=/home/ana/planner
LAB as 'rm -rf ~/.config/planner'

block install
run $P 'npm install -E -D electron@45.0.0'
run $P 'npm pkg set main=electron/main.mjs scripts.start="electron ."'
run $P 'grep -E "\"main\"|\"start\"|electron\"" package.json'

put first-window.md electron/main.mjs $P/electron/main.mjs
put first-window.md desk.mjs $P/desk.mjs
block first
run $P 'npm run build > /dev/null'
run $P 'xvfb-run -a node desk.mjs'

put serving-the-site.md electron/main.mjs $P/electron/main.mjs
put preload-and-ipc.md electron/preload.cjs $P/electron/preload.cjs
block served
run $P 'xvfb-run -a node desk.mjs --click Statistics'

python3 - "$M$P/src/device.ts" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
a = 'export async function exportPlan(plan: Plan): Promise<string> {\n'
b = ('// In the desktop app, Electron\'s preload puts this on window; in a browser or a phone it is absent.\n'
     'const desktop = (window as { desktop?: { exportPlan: (text: string) => Promise<string> } }).desktop;\n\n'
     'export async function exportPlan(plan: Plan): Promise<string> {\n'
     '  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;\n')
assert s.count(a) == 1; p.write_text(s.replace(a, b))
PY
block export
run $P 'npm run build > /dev/null'
run $P "xvfb-run -a node desk.mjs --click 'Export plan' --wait 500 | tail -n 3"
run $P 'ls ~/.config/planner'
run $P 'head -c 80 ~/.config/planner/planner-export.json; echo'

block isolated
run $P "xvfb-run -a node desk.mjs --eval 'typeof require' --eval 'typeof process' --eval 'Object.keys(window.desktop)' --eval 'window.desktop.exportPlan(123)' | head -n 4"

block browser-still
serve $P 5173 'npm run dev'
run $P "node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Export plan' --wait 300 | tail -n 1"
unserve

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 14:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 14:00:00 -0300'"
run $P 'git add . && git commit -q -m "The planner as a desktop app, with Electron" && git log --oneline -1'
save_as 11
