#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of front-multiplatform, as a script
# that produces them; lab/fill.py pastes each block into its fence.
#
#   sudo bash captures.sh > out.txt
#
# It starts from what lesson 9 left. lib/main.dart is taken from flutter.md,
# and the Ionic page's two files from ionic.md, by lab/extract.py.
#
# STAGED, beyond what lab.sh says for every lesson:
#   - Flutter 3.47.8 was installed in ~/.local/flutter with the two lines the
#     lesson prints, once, before this script; it is a 1.6 GB download, and
#     the script starts from it rather than repeating it. Its analytics are
#     turned off with `flutter --disable-analytics`, which prints a notice.
#   - The two static servers (npm run preview, and vite preview pointed at
#     Flutter's build) run in the background.
#   - The commits carry fixed dates.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
. "$(dirname "$0")/../../lab/capture-lib.sh"
start_from 9
LAB as 'rm -rf ~/planner_flutter ~/planner-ionic'
F=/home/ana/planner_flutter
I=/home/ana/planner-ionic
RUNENV='export PATH=$HOME/.local/flutter/bin:$PATH'
quiet /home/ana 'flutter --disable-analytics'

block flutter-version
run /home/ana 'flutter --version'
block flutter-create
run /home/ana 'flutter create --platforms web --empty --project-name planner_flutter planner_flutter'
put flutter.md lib/main.dart $F/lib/main.dart
block flutter-build
run /home/ana 'cd planner_flutter'
run $F 'flutter analyze'
run $F 'flutter build web --no-web-resources-cdn'
run $F 'du -sh build/web'
RUNENV=
serve /home/ana/planner 4174 'npx vite preview --outDir ../planner_flutter/build/web --port 4174'
block flutter-look
U="'http://localhost:4174/?today=2026-10-21'"
run /home/ana/planner "node look.mjs $U --wait 4000 2>&1 | grep -v '^console'"
run /home/ana/planner "node look.mjs $U --wait 4000 --eval 'document.querySelector(\"flt-semantics-placeholder\").click()' --wait 1500 --click 'Spanish A2' --wait 500 --click 'Mark done' --wait 500 2>&1 | grep -v '^console'"
unserve

block ionic-create
run /home/ana 'npm create vite@9.3.1 planner-ionic -- --template vanilla-ts --no-interactive > /dev/null'
run /home/ana 'cd planner-ionic'
run $I 'rm -r src public && mkdir src'
run $I 'npm install -E -D vite@8.3.5 typescript@6.0.3 > /dev/null'
run $I 'npm install -E @ionic/core@9.0.9'
run $I 'cp ../planner/src/planner.ts ../planner/public/courses.json src/'
put ionic.md index.html $I/index.html
put ionic.md src/main.ts $I/src/main.ts
block ionic-build
run $I 'npm run build | tail -n 7'
serve $I 4175 'npx vite preview --port 4175'
block ionic-look
run /home/ana/planner "node look.mjs 'http://localhost:4175/?today=2026-10-21' --wait 1500"
unserve
save_as 10
