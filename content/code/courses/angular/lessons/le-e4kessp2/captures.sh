#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of angular, as a script that
# produces them. The output is not committed: lab/redo.sh pastes it into the
# lesson's fences.
#
# It starts from the ~/planner lesson 24's captures left, which this lesson
# does not change, and makes four small projects beside it in ~/compare: a new
# Angular project from @angular/cli 21.2.29 on the planner's versions, and
# create-vite 9.3.1's react-ts, vue-ts and svelte-ts templates, with what they
# depend on from the npm registry and React 19.3.1, Vue 3.5.44 and Svelte
# 5.57.3 pinned, as npm installed them on the day of the recording.
#
# What is STAGED rather than typed: the four cards and their entry files,
# taken whole out of the sections that show them; each dev server in a
# terminal of its own, stopped before the next starts.
set -uo pipefail
cd "$(dirname "$0")"
source ../../lab/lib.sh
bash "$LAB_SH" down >/dev/null 2>&1; sleep 1
restore le-ydq5jhh3
quiet '~' 'rm -rf compare'
C='~/compare'
look_at() { cap "$1" "look http://localhost:$2/ --do 'check Sat 24 Oct, 50 minutes' --text body"; }

# one-card: Angular
cap '~' 'mkdir compare'
cap $C 'npx @angular/cli@21.2.29 new angular --defaults --skip-git --skip-install --ssr=false'
cap $C/angular 'cp ~/planner/.npmrc .'
cap $C/angular 'npm install --save-exact @angular/common@21.2.25 @angular/compiler@21.2.25 @angular/core@21.2.25 @angular/forms@21.2.25 @angular/platform-browser@21.2.25 @angular/router@21.2.25 rxjs@7.8.2 tslib@2.8.1 @angular/build@21.2.29 @angular/cli@21.2.29 @angular/compiler-cli@21.2.25 jsdom@28.1.0 prettier@3.9.10 typescript@5.9.3 vitest@4.1.12'
cap $C/angular 'rm src/app/app.html src/app/app.css src/app/app.spec.ts src/app/app.routes.ts'
shown "$PWD/one-card.md" src/app/app.ts $C/angular/src/app/app.ts
shown "$PWD/one-card.md" src/app/app.config.ts $C/angular/src/app/app.config.ts
bg ng $C/angular 'npx ng serve'; wait_log ng 'Watch mode enabled'; wait_port 4200
look_at $C/angular 4200
bg_stop ng

# react
cap $C 'npm create vite@9.3.1 -- react --template react-ts --no-immediate'
cap $C/react 'npm install'
cap $C/react 'npm install --save-exact react@19.3.1 react-dom@19.3.1 @types/node@22.20.5 @types/react@19.3.0 @types/react-dom@19.3.0 @vitejs/plugin-react@6.1.2 oxlint@1.90.0 typescript@6.0.3 vite@8.3.5'
cap $C/react 'rm src/App.tsx src/App.css src/index.css'
shown "$PWD/react.md" src/WeekCard.tsx $C/react/src/WeekCard.tsx
shown "$PWD/react.md" src/main.tsx $C/react/src/main.tsx
bg rx $C/react 'npm run dev'; wait_port 5173
look_at $C/react 5173
bg_stop rx

# vue
cap $C 'npm create vite@9.3.1 -- vue --template vue-ts --no-immediate'
cap $C/vue 'npm install'
cap $C/vue 'npm install --save-exact vue@3.5.44 @vitejs/plugin-vue@6.0.10 @vue/tsconfig@0.9.1 @types/node@22.20.5 typescript@6.0.3 vite@8.3.5 vue-tsc@3.3.14'
cap $C/vue 'rm -r src/App.vue src/components src/style.css'
shown "$PWD/vue.md" src/WeekCard.vue $C/vue/src/WeekCard.vue
shown "$PWD/vue.md" src/main.ts $C/vue/src/main.ts
bg vu $C/vue 'npm run dev'; wait_port 5173
look_at $C/vue 5173
bg_stop vu

# svelte
cap $C 'npm create vite@9.3.1 -- svelte --template svelte-ts --no-immediate'
cap $C/svelte 'npm install'
cap $C/svelte 'npm install --save-exact svelte@5.57.3 @sveltejs/vite-plugin-svelte@7.3.1 @tsconfig/svelte@5.0.8 @types/node@22.20.5 svelte-check@4.7.7 typescript@6.0.3 vite@8.3.5'
cap $C/svelte 'npm audit 2>&1 | head -9'
cap $C/svelte 'rm -r src/App.svelte src/lib src/app.css'
shown "$PWD/svelte.md" src/WeekCard.svelte $C/svelte/src/WeekCard.svelte
shown "$PWD/svelte.md" src/main.ts $C/svelte/src/main.ts
bg sv $C/svelte 'npm run dev'; wait_port 5173
look_at $C/svelte 5173
bg_stop sv

# what-comes-in-the-box
cap $C 'for p in react vue svelte; do (cd $p && npm run build > /dev/null); done; (cd angular && npx ng build > /dev/null)'
cap $C 'for f in react/dist/assets/*.js vue/dist/assets/*.js svelte/dist/assets/*.js angular/dist/angular/browser/main-*.js; do printf "%-48s %7d bytes, %6d gzipped\n" $f $(wc -c < $f) $(gzip -9c $f | wc -c); done'

snapshot le-e4kessp2
