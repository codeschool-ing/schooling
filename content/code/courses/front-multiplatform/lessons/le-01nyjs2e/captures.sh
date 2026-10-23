#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from the planner lesson 1 left (lab/capture-lib.sh, start_from).
#
# STAGED, beyond what lab.sh says for every lesson:
#   - The commits carry fixed dates, so their hashes repeat.
#   - "stale" edits src/view.ts with the sed the lesson prints, and puts it
#     back with git checkout afterwards, rebuilding and syncing quietly, so
#     the lessons after this one start from the planner as lesson 1 wrote it.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 1
P=/home/ana/planner
RUNENV="export GIT_AUTHOR_DATE='2026-10-21 10:00:00 -0300' GIT_COMMITTER_DATE='2026-10-21 10:00:00 -0300'"

block left
run $P 'git status --short'
run $P 'git add look.mjs package.json package-lock.json'
run $P 'git commit -q -m "Look at the planner from the terminal"'

block core
run $P 'npm install -E @capacitor/core@8.5.3'
run $P 'npm install -E -D @capacitor/cli@8.5.3'

block init
run $P 'npx cap init "Study planner" com.example.studyplanner --web-dir dist'
run $P 'cat capacitor.config.ts'

block platforms
run $P 'npm install -E @capacitor/android@8.5.3 @capacitor/ios@8.5.3'
run $P 'npx cap add android'
run $P 'npx cap add ios'

block status
run $P 'git status --short'
run $P 'ls android ios/App'

block doctor
run $P 'npx cap doctor | grep -E "installed|Xcode"'

block ignored
run $P 'git check-ignore -v android/app/src/main/assets/public ios/App/App/public'

block assets
run $P 'ls android/app/src/main/assets android/app/src/main/assets/public'
run $P 'cat android/app/src/main/assets/capacitor.config.json'

block stale
run $P 'grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js'
run $P "sed -i 's/All courses/Back to courses/' src/view.ts"
run $P 'npx cap sync android'
run $P 'grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js'

block fresh
run $P 'npm run build && npx cap sync android'
run $P 'grep -oE "(Back to|All) courses" android/app/src/main/assets/public/assets/*.js'
quiet $P 'git checkout src/view.ts && npm run build && npx cap sync'

block commit
run $P 'git add .'
run $P 'git commit -q -m "Capacitor, and the Android and iOS projects"'
run $P 'git log --oneline'
save_as 2
