#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of angular, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it (lab/fill.py pastes them).
#
#   sudo bash ../../lab.sh up
#   sudo bash captures.sh > out.txt && python3 ../../lab/fill.py <section>.md out.txt
#
# It needs the network: npx fetches the Angular CLI, npm installs the project,
# and ng update asks the registry.
#
# It starts from nothing: no ~/planner, no look. It ends by saving ~/planner
# for lesson 3 (lib.sh's snapshot).
#
# What is STAGED rather than typed: the files ana writes, taken out of the
# lesson's .md by lab/shown.py (.npmrc, package.json, look.mjs, app.html,
# courses.json, app.spec.ts); the two servers she starts "in a second
# terminal", which run in the background and whose output is printed where
# the lesson shows that terminal.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, npm 10.9.4 and the Angular
# CLI 21.2.28, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
quiet '~' 'rm -rf ~/planner ~/js-tools/look.mjs ~/.local/bin/look ~/.npm/_npx'

cap '~' 'npx @angular/cli@21.2.28 new planner --style=css --ssr=false --zoneless --ai-config=none'
save a-project .npmrc
save a-project package.json
cap '~/planner' 'npm install' 'npm ls --depth=0' 'du -sh node_modules'
cap '~/planner' 'git init -q' 'git add -A' 'git commit -q -m "A new Angular project"' 'git show --stat --oneline | tail -1' 'wc -l package-lock.json'

cap '~/planner' 'ls -A'
cap '~/planner' "node -e \"console.log(Object.keys(require('./angular.json').projects.planner.architect))\""
cap '~/planner' 'find src public -type f | sort'
for f in src/index.html src/main.ts src/app/app.config.ts src/app/app.ts; do
  block "cat $f"
  session '~/planner' "cat $f"
done

shown "$PWD/ng-serve.md" look.mjs '~/js-tools/look.mjs'
quiet '~' "cat > ~/.local/bin/look <<'END'
#!/bin/sh
exec node \"\$HOME/js-tools/look.mjs\" \"\$@\"
END
chmod +x ~/.local/bin/look"
serve
cap_bg serve
cap '~/planner' 'ps -o rss=,args= -u ana | sort -rn | head -3'
cap '~/planner' 'npx ng serve'
cap_look http://localhost:4200/ --text h1
save ng-serve src/app/app.html
wait_log serve 'Component update'
sleep 1
cap_bg serve
cap_look http://localhost:4200/
save ng-serve public/courses.json
cap '~/planner' 'curl -si http://localhost:4200/courses.json | head -1'
bg_stop serve
serve
cap_bg serve
cap '~/planner' 'curl -s http://localhost:4200/courses.json | head -4'
cap '~/planner' 'curl -si http://localhost:4200/courses/git | head -1'

cap '~/planner' 'npx ng generate component week-summary --dry-run'
cap '~/planner' 'npx ng generate component week-summary' 'cat src/app/week-summary/week-summary.ts'

cap '~/planner' 'npx ng build'
cap '~/planner' "node -e \"console.log(require('./angular.json').projects.planner.architect.build.configurations.production.budgets)\""
cap '~/planner' 'ls dist/planner/browser'
bg static '~/planner' 'python3 -m http.server 8081 --directory dist/planner/browser'
wait_port 8081
cap_bg static
cap_look http://127.0.0.1:8081/
cap_look http://127.0.0.1:8081/courses/git
cap_bg static
bg_stop static

cap '~/planner' 'npx ng test --watch=false'
cap '~/planner' 'cat src/app/app.spec.ts'
save ng-test src/app/app.spec.ts
cap '~/planner' 'npx ng test --watch=false'

cap '~/planner' 'npx ng update'
cap '~/planner' "npm view @angular/core time --json | grep -E '\"2[0-2]\\.0\\.0\"'"
cap '~/planner' 'npx ng update @angular/core@22 @angular/cli@22 2>&1 | tail -5'
cap '~/planner' 'git status --short' 'git add -A' 'git commit -q -m "The CLI: serve, generate, build, test"' 'npx ng update @angular/core@22 @angular/cli@22 2>&1 | tail -5'
cap '~/planner' 'npx ng update @angular/core@21 @angular/cli@21'

bg_stop serve
snapshot le-vs2rnyr2
