#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of react-native, as a script that
# produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from an empty home with Node.js installed.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The reports of `init`, create-expo-app and `expo prebuild` go to
#     /dev/null: each draws a spinner and characters the interface has no
#     glyph for. `ls`, `find` and `grep` show what they wrote.
#   - The two edits the lesson asks for in app.json (the package name, then
#     the plugin) are made by a node one-liner here, where the student uses
#     an editor; the `grep` after each shows the result.
#   - plugins/with-week-start.js is taken from config-plugins.md by
#     lab/extract.py.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
B=/home/ana/Bare
E=/home/ana/try-expo
edit() { # edit 'js expression on c, the parsed app.json'
  LAB as "$LID" "cd $E && node -e 'const fs=require(\"fs\");const c=JSON.parse(fs.readFileSync(\"app.json\"));$1;fs.writeFileSync(\"app.json\",JSON.stringify(c,null,2)+\"\\n\")'"
}

block bare
run /home/ana 'npx @react-native-community/cli@20.2.0 init Bare --version 0.88.1 --skip-install --skip-git-init > /dev/null 2>&1'
run /home/ana 'ls Bare'
run /home/ana 'ls Bare/android Bare/ios'
run /home/ana 'find Bare/android Bare/ios -type f | wc -l'

block create
run /home/ana 'npx create-expo-app@5.0.0 try-expo --template blank-typescript@sdk-58 > /dev/null 2>&1'
run /home/ana 'cd try-expo'
run $E 'ls'
run $E 'tail -3 .gitignore'

block prebuild
run $E 'npx expo prebuild --no-install > /dev/null 2>&1'
run $E 'ls android ios'
run $E 'grep applicationId android/app/build.gradle'

edit 'c.expo.android.package="org.example.planner"'
block package
run $E 'grep -n package app.json'
run $E 'npx expo prebuild --clean --no-install > /dev/null 2>&1'
run $E 'grep applicationId android/app/build.gradle'

put config-plugins.md plugins/with-week-start.js $E/plugins/with-week-start.js
edit 'c.expo.plugins=[["./plugins/with-week-start.js",{"day":"monday"}]]'
block plugin
run $E 'grep -A7 "\"plugins\"" app.json'
run $E 'npx expo prebuild --clean --no-install > /dev/null 2>&1'
run $E 'grep WEEK android/app/src/main/AndroidManifest.xml'
run $E 'grep -A1 PlannerWeekStarts ios/tryexpo/Info.plist'
