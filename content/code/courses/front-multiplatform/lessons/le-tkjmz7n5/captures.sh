#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 8 left. Nothing here talks to Expo's servers:
# EAS Build and EAS Update need an account and were not run (lab.sh), and
# `npx expo prebuild` and `npx expo export` work on the machine alone.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - "identity" adds android.package and ios.bundleIdentifier, and later
#     "runtime" adds runtimeVersion, to app.json by exact edits (python
#     below), shown afterwards with grep.
#   - `npx expo export` goes to /dev/null: its report draws with U+203A.
#   - The commit carries a fixed date.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 8
N=/home/ana/planner-native
edit_app() { python3 - "$M$N/app.json" "$1" "$2" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); s = p.read_text()
assert s.count(sys.argv[2]) == 1, sys.argv[2]
p.write_text(s.replace(sys.argv[2], sys.argv[3]))
PY
}

block ignored
run $N 'grep -n -B1 "^/android" .gitignore'

block prebuild-anon
run $N 'npx expo prebuild --platform android --no-install'
run $N 'grep applicationId android/app/build.gradle'

block identity
run $N 'rm -rf android && git checkout app.json package.json'
edit_app '"supportsTablet": true
    },' '"supportsTablet": true,
      "bundleIdentifier": "com.example.studyplanner"
    },'
edit_app '"predictiveBackGestureEnabled": false
    },' '"predictiveBackGestureEnabled": false,
      "package": "com.example.studyplanner"
    },'
run $N 'grep -E "bundleIdentifier|\"package\"" app.json'

block prebuild
run $N 'npx expo prebuild --platform android --no-install'
run $N 'ls android'
run $N 'grep applicationId android/app/build.gradle'
run $N 'git status --short'

block regenerate
run $N 'rm -rf android'
run $N 'git status --short'

block updates-install
run $N 'npx expo install expo-updates > /dev/null'
run $N 'npm install -E expo-updates@58.0.18 > /dev/null'
run $N 'grep expo-updates package.json'

block export
run $N 'npx expo export --platform android > /dev/null'
run $N 'ls dist dist/_expo/static/js/android'
run $N 'file dist/_expo/static/js/android/*.hbc'
run $N "node -p \"const m = require('./dist/metadata.json').fileMetadata.android; m.assets.length + ' assets, and ' + m.bundle\""

edit_app '"version": "1.0.0",' '"version": "1.0.0",
    "runtimeVersion": { "policy": "appVersion" },'
block runtime
run $N 'grep -E "\"version\"|runtimeVersion" app.json'

block commit
RUNENV="export GIT_AUTHOR_DATE='2026-10-23 11:00:00 -0300' GIT_COMMITTER_DATE='2026-10-23 11:00:00 -0300'"
run $N 'git add . && git commit -q -m "An identity, generated native projects and updates" && git log --oneline -1'
save_as 9
