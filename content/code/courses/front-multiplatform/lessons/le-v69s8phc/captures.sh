#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the planner lesson 2 left. Nothing here builds an app: the
# recording machine has no Android SDK and no Xcode (lab.sh says why), and
# "no-sdk" and "no-studio" are what Capacitor says about that.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "survives" edits two files with the sed lines it prints, syncs, shows
#     what is left, and puts both back with git checkout.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 2
P=/home/ana/planner

block manifest
run $P 'cat android/app/src/main/AndroidManifest.xml'

block activity
run $P 'cat android/app/src/main/java/com/example/studyplanner/MainActivity.java'
run $P 'grep -E "applicationId|versionCode|versionName" android/app/build.gradle'
run $P 'head -n 5 android/variables.gradle'

block jdk
run $P 'grep -A3 compileOptions android/app/capacitor.build.gradle'
run $P 'java -version'

block no-sdk
run $P 'npx cap run android'

block no-studio
run $P 'npx cap open android'

block ios
run $P 'ls ios/App/App'
run $P 'grep -A1 -E "CFBundle(DisplayName|Identifier|ShortVersionString|Version)<" ios/App/App/Info.plist'
run $P 'head -n 12 ios/App/App/AppDelegate.swift'

block package
run $P 'head -n 4 ios/App/CapApp-SPM/Package.swift'
run $P 'head -n 1 android/app/capacitor.build.gradle'

block survives
run $P "sed -i 's/>Study planner</>Planner</' android/app/src/main/res/values/strings.xml"
run $P "sed -i '1a // a line of mine' android/app/capacitor.build.gradle"
run $P 'git status --short'
run $P 'npx cap sync android'
run $P 'git status --short'
run $P 'grep app_name android/app/src/main/res/values/strings.xml'
quiet $P 'git checkout android'
save_as 3
