#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 14 left. scripts/version.mjs is taken from
# one-source.md and the updater's function from desktop-updates.md by
# lab/extract.py; the two lines that call it are put into electron/main.mjs by
# exact replacement (python below), as the lesson shows them.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The release folder is served by Python's http.server on port 8080 in
#     the background, as the lesson says to do in a second terminal.
#   - The installed AppImage runs as in lesson 13: APPIMAGE_EXTRACT_AND_RUN=1,
#     on Xvfb, stopped by timeout. The runtime lists the files it unpacks; the
#     grep in the transcript leaves that list out.
#   - The updater's signing key is made with a password on the command line,
#     because the recording machine had no keyboard (lesson 14 did the same).
#   - Commits and tags carry fixed dates.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 14
P=/home/ana/planner
LAB as 'rm -rf ~/installed ~/.cache/planner-updater ~/keys/planner-updater.key*'
DATES="export GIT_AUTHOR_DATE='2026-10-24 10:00:00 -0300' GIT_COMMITTER_DATE='2026-10-24 10:00:00 -0300'"

block versions-before
run $P 'grep -n "\"version\"" package.json src-tauri/tauri.conf.json'
run $P 'grep -n "versionCode\|versionName" android/app/build.gradle'
run $P 'grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" ios/App/App.xcodeproj/project.pbxproj'

put one-source.md scripts/version.mjs $P/scripts/version.mjs
block wire
run $P "sed -i 's|\"version\": \"0.1.0\"|\"version\": \"../package.json\"|' src-tauri/tauri.conf.json"
run $P 'npm pkg set scripts.version="node scripts/version.mjs && git add android ios"'
RUNENV=$DATES
run $P 'git add . && git commit -q -m "One version, in package.json" && git log --oneline -1'
block bump
run $P 'npm version minor'
run $P 'grep -n "versionCode\|versionName" android/app/build.gradle'
run $P 'grep -c "MARKETING_VERSION = 0.2.0;" ios/App/App.xcodeproj/project.pbxproj'
run $P 'git log --oneline -2 && git tag'
RUNENV=

block updater-install
run $P 'npm install -E electron-updater@6.8.11 > /dev/null 2>&1'
run $P 'npm pkg set build.publish.provider=generic build.publish.url=http://localhost:8080/'
put desktop-updates.md electron/updater.mjs $P/electron/updater.mjs
python3 - "$M$P/electron/main.mjs" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
def fix(a, b):
    global s
    assert s.count(a) == 1, a; s = s.replace(a, b)
fix('import { fileURLToPath, pathToFileURL } from "node:url";\n',
    'import { fileURLToPath, pathToFileURL } from "node:url";\nimport { checkForUpdates } from "./updater.mjs";\n')
fix('app.whenReady().then(() => {\n  serveSite();\n',
    'app.whenReady().then(() => {\n  serveSite();\n  checkForUpdates();\n')
p.write_text(s)
PY
LAB root 'chown -R ana:ana /home/ana'
RUNENV=$DATES
run $P 'git add . && git commit -q -m "Check for updates at start" && git log --oneline -1'
RUNENV=
block installed
run $P 'rm -rf release && npx electron-builder --linux AppImage 2>&1 | grep -o "target=.*"'
run $P 'mkdir ~/installed && cp release/planner-0.2.0-x86_64.AppImage ~/installed/'
block next
RUNENV="export GIT_AUTHOR_DATE='2026-10-24 11:00:00 -0300' GIT_COMMITTER_DATE='2026-10-24 11:00:00 -0300'"
run $P 'npm version minor'
RUNENV=
run $P 'npx electron-builder --linux AppImage > /dev/null 2>&1; ls release'
run $P 'cat release/latest-linux.yml'

serve $P 8080 'python3 -m http.server 8080 --directory release'
block update
run /home/ana 'xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 40 installed/planner-0.2.0-x86_64.AppImage 2>/dev/null | grep -v appimage_extracted"'
block replaced
run /home/ana 'ls installed'
run /home/ana 'sha256sum installed/*.AppImage planner/release/planner-0.3.0-x86_64.AppImage | cut -c1-16,66-'
block tampered
run /home/ana 'rm -rf installed/* ~/.cache/planner-updater && cp planner/release/planner-0.2.0-x86_64.AppImage installed/'
run /home/ana 'printf x >> planner/release/planner-0.3.0-x86_64.AppImage'
run /home/ana 'xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 40 installed/planner-0.2.0-x86_64.AppImage 2>/dev/null | grep -E \"^(up to date|update)|sha512\" | cut -c1-110"'
unserve
quiet $P 'rm -rf release ~/.cache/planner-updater'
# An AppImage stopped by timeout leaves its unpacked copy in /tmp, a tmpfs.
LAB root 'rm -rf /tmp/appimage_extracted_*'

block tauri-key
run $P 'npx tauri signer generate --ci -p recording-machine-only -w ~/keys/planner-updater.key 2>&1 | grep -v "^ *$" | head -n 4'
run $P 'ls ~/keys'
save_as 15
