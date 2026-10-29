#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l22.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l22.txt; done
#
# Starts from ~/vue as lesson 21 left it, on Node 22.23.4, and makes three
# small projects in ~/vue/compare: create-vite 9.3.1's vue-ts, react-ts and svelte-ts
# templates and @angular/cli 22.2.4's new project, with what they depend on
# from the npm registry and React 19.3.1, Svelte 5.57.2 and Angular 22.2.3
# pinned. The four cards and the two main files are taken whole out of the
# sections that show them. The page needs no clock.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
C='~/vue/compare'
NG='@angular/common@22.2.3 @angular/compiler@22.2.3 @angular/core@22.2.3 @angular/forms@22.2.3 @angular/platform-browser@22.2.3 @angular/router@22.2.3'
node22() {
  bash "$LAB_SH" script 'node --version' | grep -q v22.23.4 && return
  quiet '~' 'curl -fsSLO https://nodejs.org/dist/v22.23.4/node-v22.23.4-linux-x64.tar.xz &&
    rm -rf ~/.local/node && mkdir ~/.local/node &&
    tar -xJf node-v22.23.4-linux-x64.tar.xz -C ~/.local/node --strip-components=1 && rm node-v22.23.4-linux-x64.tar.xz'
}
files() {
  node22
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-rw7d8e2n
node22
quiet '~/vue' 'mkdir -p compare'

# Vue
block vue-create
session $C 'npm create vite@9.3.1 -- vue --template vue-ts --no-immediate'
block vue-install
session $C/vue 'npm install' 'npm install --save-exact vue@3.5.44' 'rm -r src/App.vue src/components src/style.css'
shown one-card-four-ways.md src/WeekCard.vue $C/vue/src/WeekCard.vue
shown one-card-four-ways.md src/main.ts $C/vue/src/main.ts
dev vu $C/vue 'npm run dev' 5173
block vue-look
session $C/vue "look http://localhost:5173/ --do 'check text=23 October' --text body"
bg_stop vu

# React
block react-create
session $C 'npm create vite@9.3.1 -- react --template react-ts --no-immediate'
block react-install
session $C/react 'npm install' 'npm install --save-exact react@19.3.1 react-dom@19.3.1' 'rm src/App.tsx src/App.css'
shown react.md src/WeekCard.tsx $C/react/src/WeekCard.tsx
shown react.md src/main.tsx $C/react/src/main.tsx
dev rx $C/react 'npm run dev' 5173
block react-look
session $C/react "look http://localhost:5173/ --do 'check text=23 October' --text body"
bg_stop rx

# Angular
block angular-create
session $C 'npx --yes @angular/cli@22.2.4 new angular --defaults --skip-git --skip-install --ssr=false'
block angular-install
session $C/angular 'npm install' "npm install --save-exact $NG"
block angular-audit
session $C/angular 'npm audit'
block angular-override
session $C/angular 'npm pkg set overrides.vite=8.3.5' 'npm install' 'npm ls vite'
shown angular.md src/app/week-card.ts $C/angular/src/app/week-card.ts
shown angular.md src/main.ts $C/angular/src/main.ts
dev ng $C/angular 'npm start' 4200
sleep 2
block angular-serve
bg_show ng
block angular-look
session $C/angular "look http://localhost:4200/ --do 'check text=23 October' --text body"
bg_stop ng

# Svelte
block svelte-create
session $C 'npm create vite@9.3.1 -- svelte --template svelte-ts --no-immediate'
block svelte-install
session $C/svelte 'npm install' 'npm install --save-dev --save-exact svelte@5.57.2' 'rm -r src/App.svelte src/app.css src/lib'
shown svelte.md src/WeekCard.svelte $C/svelte/src/WeekCard.svelte
shown svelte.md src/main.ts $C/svelte/src/main.ts
dev sv $C/svelte 'npm run dev' 5173
block svelte-look
session $C/svelte "look http://localhost:5173/ --do 'check text=23 October' --text body"
bg_stop sv

# compared
block sizes
session $C 'du -sh vue/node_modules react/node_modules angular/node_modules svelte/node_modules'
block builds
session $C '(cd vue && npm run build 2>&1 | grep -E "\.js|\.css")' \
  '(cd react && npm run build 2>&1 | grep -E "\.js|\.css")' \
  '(cd angular && npx ng build 2>&1 | grep -E "^(main|styles|Initial)")' \
  '(cd svelte && npm run build 2>&1 | grep -E "\.js|\.css")'
snapshot
