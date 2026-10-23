#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the planner lesson 3 left. src/device.ts, src/view.ts,
# src/main.ts and look.mjs are taken from the-new-code.md by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `npm run dev` runs in the background, as lesson 1 has the student run it
#     in a terminal of its own.
#   - ~/notes.png, the picture "photo" uploads, is a 64x48 white PNG made with
#     ImageMagick's convert; any picture does.
#   - "native" shows the two files after the edits the section describes,
#     made here by exact insertions (python below): two lines in
#     AndroidManifest.xml and four keys in Info.plist.
#   - The commit carries a fixed date, so its hash repeats.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 3
P=/home/ana/planner
U="'http://localhost:5173/?today=2026-10-21'"

block install
run $P 'npm install -E @capacitor/preferences@8.0.1 @capacitor/filesystem@8.1.5 @capacitor/local-notifications@8.3.1 @capacitor/geolocation@8.2.4 @capacitor/camera@8.2.6'
run $P 'npx cap sync'

for f in src/device.ts src/view.ts src/main.ts look.mjs; do put the-new-code.md $f $P/$f; done
block build
run $P 'npm run build'

serve $P 5173 'npm run dev'
block prefs
run $P "node look.mjs $U --click 'Spanish A2' --click 'Mark done' --reload --eval 'Object.keys(localStorage)' --eval 'localStorage.length'"

block export
run $P "node look.mjs $U --click 'Export plan' --wait 300 | tail -n 3"

block remind-prompt
run $P "node look.mjs $U --click Guitar --click 'Remind me on 2026-10-21' --wait 300 | tail -n 2"
block remind
run $P "node look.mjs $U --click Guitar --grant notifications --click 'Remind me on 2026-10-21' --wait 300 | tail -n 2"

block where
run $P "node look.mjs $U --click 'Where am I?' --wait 300 | tail -n 1"
run $P "node look.mjs $U --grant geolocation --geo -23.561,-46.656 --click 'Where am I?' --wait 300 | tail -n 1"

block photo
quiet $P 'convert -size 64x48 xc:white ~/notes.png'
run $P "node look.mjs $U --click Guitar --upload ~/notes.png --click 'Photo of my notes' --wait 500 | tail -n 2"
unserve

block plugin-manifests
run $P 'grep -c uses-permission node_modules/@capacitor/*/android/src/main/AndroidManifest.xml'

python3 - "$M$P" <<'PY'
import sys, pathlib
root = pathlib.Path(sys.argv[1])
m = root / "android/app/src/main/AndroidManifest.xml"
s = m.read_text()
a = '    <uses-permission android:name="android.permission.INTERNET" />\n'
assert a in s
m.write_text(s.replace(a, a + '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n'
                          '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n'))
p = root / "ios/App/App/Info.plist"
s = p.read_text()
a = "<dict>\n"
keys = ("\t<key>NSCameraUsageDescription</key>\n\t<string>To take a photo of your notes for a session.</string>\n"
        "\t<key>NSPhotoLibraryUsageDescription</key>\n\t<string>To attach a photo of your notes from your library.</string>\n"
        "\t<key>NSPhotoLibraryAddUsageDescription</key>\n\t<string>To save a photo of your notes to your library.</string>\n"
        "\t<key>NSLocationWhenInUseUsageDescription</key>\n\t<string>To show where you are studying, only when you ask.</string>\n")
i = s.index(a)
p.write_text(s[: i + len(a)] + keys + s[i + len(a):])
PY
block native
run $P 'grep -n uses-permission android/app/src/main/AndroidManifest.xml'
run $P 'grep -A1 UsageDescription ios/App/App/Info.plist'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 14:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 14:00:00 -0300'"
run $P 'npm run build > /dev/null && npx cap sync > /dev/null'
run $P 'git add .'
run $P 'git commit -q -m "Keep the plan, export it, remind, locate and photograph"'
run $P 'git log --oneline -1'
save_as 4
