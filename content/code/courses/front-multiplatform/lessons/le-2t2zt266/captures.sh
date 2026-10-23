#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the planner lesson 4 left, and from no ~/keep-awake. The
# plugin's four files are taken from the lesson by lab/extract.py; the edits
# to the planner are the ones the-planner-uses-it.md shows, applied by exact
# replacement (python below). Nothing native is compiled: there is no Android
# SDK and no Xcode here (lab.sh), and the lesson says so.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - `npm init @capacitor/plugin` asks nothing when every answer is given on
#     the line; its output is sent to /dev/null in the transcript because its
#     last lines draw with emoji the interface has no glyph for.
#   - `npm run build` in the plugin goes to /dev/null for the same reason:
#     docgen marks each file it writes with an emoji.
#   - Removing the generated test target from Package.swift is an exact
#     replacement, shown after it with sed.
#   - `npm run dev` runs in the background; commits carry fixed dates.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 4
LAB as 'rm -rf ~/keep-awake'
K=/home/ana/keep-awake
P=/home/ana/planner
RUNENV="export GIT_AUTHOR_DATE='2026-10-22 09:00:00 -0300' GIT_COMMITTER_DATE='2026-10-22 09:00:00 -0300'"

block generate
run /home/ana 'npm init @capacitor/plugin@0.22.0 keep-awake -- --name capacitor-keep-awake --package-id com.example.keepawake --class-name KeepAwake --repo https://example.org/keep-awake --author "Ana Lima <ana@example.org>" --license MIT --description "Keep the screen on while a study session runs" --android-lang kotlin > /dev/null'
run /home/ana 'cd keep-awake'
run $K "git ls-files ':!example-app' ':!*/gradle/wrapper/*' ':!*.gitkeep'"

block index
run $K 'cat src/index.ts'

block tidy
run $K 'git rm -rq example-app ios/Tests android/src/test android/src/androidTest android/src/main/kotlin/com/example/keepawake/KeepAwake.kt ios/Sources/KeepAwakePlugin/KeepAwake.swift'
python3 - "$M$K/Package.swift" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
a = '''            path: "ios/Sources/KeepAwakePlugin"),
        .testTarget(
            name: "KeepAwakePluginTests",
            dependencies: ["KeepAwakePlugin"],
            path: "ios/Tests/KeepAwakePluginTests")
    ]'''
b = '''            path: "ios/Sources/KeepAwakePlugin")
    ]'''
assert a in s; p.write_text(s.replace(a, b))
PY
run $K "sed -n '/targets: \[/,\$p' Package.swift"

put the-interface.md src/definitions.ts $K/src/definitions.ts
put the-interface.md src/web.ts $K/src/web.ts
put the-native-sides.md android/src/main/kotlin/com/example/keepawake/KeepAwakePlugin.kt $K/android/src/main/kotlin/com/example/keepawake/KeepAwakePlugin.kt
put the-native-sides.md ios/Sources/KeepAwakePlugin/KeepAwakePlugin.swift $K/ios/Sources/KeepAwakePlugin/KeepAwakePlugin.swift

block build
run $K 'npm run build > /dev/null'
run $K 'ls dist dist/esm'
block docs
run $K "grep -E '^### |^(Keep|Let|Whether) ' README.md"
block plugin-commit
run $K 'git add -A'
run $K 'git commit -q -m "Keep the screen on, on three platforms"'
run $K 'git log --oneline'

block install
run $P 'npm install -E ../keep-awake'
run $P 'grep keep-awake package.json'
run $P 'npx cap sync android | grep -A7 "plugins for android"'

python3 - "$M$P" <<'PY'
import sys, pathlib
root = pathlib.Path(sys.argv[1])
def fix(f, a, b):
    p = root / f; s = p.read_text()
    assert s.count(a) == 1, (f, a); p.write_text(s.replace(a, b))
fix("src/device.ts", 'import { Camera } from "@capacitor/camera";\n',
    'import { Camera } from "@capacitor/camera";\nimport { KeepAwake } from "capacitor-keep-awake";\n')
fix("src/device.ts", '  return `a photo, ${image.type}, ${image.size} bytes`;\n}\n',
    '  return `a photo, ${image.type}, ${image.size} bytes`;\n}\n\n'
    'export async function keepScreenOn(on: boolean): Promise<string> {\n'
    '  if (on) await KeepAwake.keepAwake();\n'
    '  else await KeepAwake.allowSleep();\n'
    '  return on ? "the screen stays on" : "the screen may sleep again";\n}\n')
fix("src/view.ts", '"export" | "where" | "photo" | "remind"', '"export" | "where" | "photo" | "remind" | "awake" | "sleep"')
fix("src/view.ts", 'button("Photo of my notes", () => act.device("photo")), said);',
    'button("Photo of my notes", () => act.device("photo")),\n'
    '    button("Keep the screen on", () => act.device("awake")), button("Let the screen sleep", () => act.device("sleep")), said);')
fix("src/main.ts", 'import { exportPlan, loadPlan, photoOfNotes, remind, savePlan, whereAmI } from "./device";',
    'import { exportPlan, keepScreenOn, loadPlan, photoOfNotes, remind, savePlan, whereAmI } from "./device";')
fix("src/main.ts", '"export" | "where" | "photo" | "remind", id', '"export" | "where" | "photo" | "remind" | "awake" | "sleep", id')
fix("src/main.ts", '    if (what === "photo") say(await photoOfNotes());\n',
    '    if (what === "photo") say(await photoOfNotes());\n'
    '    if (what === "awake" || what === "sleep") say(await keepScreenOn(what === "awake"));\n')
PY
block planner-build
run $P 'npm run build | tail -n 2'
serve $P 5173 'npm run dev'
block awake
U="'http://localhost:5173/?today=2026-10-21'"
run $P "node look.mjs $U --click Statistics --click 'Keep the screen on' --wait 300 | tail -n 1"
run $P "node look.mjs $U --click Statistics --grant screen-wake-lock --click 'Keep the screen on' --wait 300 | tail -n 1"
run $P "node look.mjs $U --click Statistics --grant screen-wake-lock --click 'Keep the screen on' --click 'Let the screen sleep' --wait 300 | tail -n 1"
unserve
block planner-commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-22 11:00:00 -0300' GIT_COMMITTER_DATE='2026-10-22 11:00:00 -0300'"
run $P 'git add . && git commit -q -m "Keep the screen on during a session" && git log --oneline -1'
save_as 5
