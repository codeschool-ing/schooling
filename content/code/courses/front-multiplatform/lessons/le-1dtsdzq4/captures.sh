#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 11 left, and installs Rust from nothing: ~/.cargo
# and ~/.rustup are removed first. src-tauri/src/lib.rs is taken from
# a-command.md by lab/extract.py; the edits to tauri.conf.json and
# src/device.ts are the ones the lesson shows, made by the sed it prints and
# by exact replacement (python below).
#
# STAGED, beyond what lab.sh says for every lesson:
#   - rustup-init comes from static.rust-lang.org, as the lesson shows, and
#     not through sh.rustup.rs, which the recording machine's gateway refuses
#     (lab.sh); the second is a script that downloads the first.
#   - The window is opened on Xvfb, as in lesson 11; nothing can drive a
#     WebKitGTK window the way Playwright drives Chromium, so the transcript
#     lists the windows on the display instead.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 11
P=/home/ana/planner
LAB as 'rm -rf ~/.cargo ~/.rustup ~/.local/share/planner ~/.local/share/com.example.studyplanner'
# rustup-init adds a line to ~/.profile and ~/.bashrc; an earlier run left it.
LAB as 'sed -i "/\.cargo\/env/d" ~/.profile ~/.bashrc'

block rust
run /home/ana 'curl -fsSLO https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init'
run /home/ana 'chmod +x rustup-init'
run /home/ana './rustup-init -y --profile minimal 2>&1 | grep -E "installed -|is installed"'
run /home/ana 'rm rustup-init'
block rust-version
run /home/ana 'rustc --version'
run /home/ana 'cargo --version'

block cli
run $P 'npm install -E -D @tauri-apps/cli@2.12.4 > /dev/null'
run $P 'npm install -E @tauri-apps/api@2.12.4 > /dev/null'
run $P 'npx tauri init --ci --app-name planner --window-title "Study planner" --frontend-dist ../dist --dev-url http://localhost:5173 --before-dev-command "npm run dev" --before-build-command "npm run build"'
run $P 'ls src-tauri src-tauri/src'

block identifier
run $P 'npx tauri build'
run $P "sed -i 's/\"com.tauri.dev\"/\"com.example.studyplanner\"/' src-tauri/tauri.conf.json"
run $P 'grep -E "productName|identifier|frontendDist|title" src-tauri/tauri.conf.json'

put a-command.md src-tauri/src/lib.rs $P/src-tauri/src/lib.rs
python3 - "$M$P/src/device.ts" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
def fix(a, b):
    global s
    assert s.count(a) == 1, a; s = s.replace(a, b)
fix('import { KeepAwake } from "capacitor-keep-awake";\n',
    'import { KeepAwake } from "capacitor-keep-awake";\nimport { invoke, isTauri } from "@tauri-apps/api/core";\n')
fix('  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;\n',
    '  if (desktop) return `exported to ${await desktop.exportPlan(JSON.stringify(plan))}`;\n'
    '  if (isTauri()) return `exported to ${await invoke<string>("export_plan", { text: JSON.stringify(plan) })}`;\n')
p.write_text(s)
PY

block test
run $P/src-tauri 'cargo test --lib 2>&1 | tail -n 6'

block build
run $P 'npx tauri build 2>&1 | tail -n 9'
run $P 'ls ~/.cargo/registry/src/*/ | wc -l'

block linked
run $P 'ldd src-tauri/target/release/app | grep -E "webkit|gtk-3" | cut -d" " -f1'

block window
run $P 'xvfb-run -a sh -c "src-tauri/target/release/app 2>/dev/null & sleep 5; xwininfo -root -tree | grep -o \"Study planner.*\" | head -n 1; kill \$!"'

block sizes
run $P 'du -sh src-tauri/target/release/app node_modules/electron/dist'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 16:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 16:00:00 -0300'"
run $P 'git status --short'
run $P 'git add . && git commit -q -m "The planner as a desktop app, with Tauri" && git log --oneline -1'
save_as 12
