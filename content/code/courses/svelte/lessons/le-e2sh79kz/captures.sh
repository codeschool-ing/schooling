#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l20.txt
#   python3 ../../lab/fill.py four-counters.md /tmp/l20.txt --blocks svelte,vue,react,angular
#
# STAGED, and said so in the lesson: four small projects in ~/compare, one per
# framework, made from the files in lab/compare (each framework's usual minimal
# setup: Vite for three, the Angular CLI's for the fourth) with the component the
# lesson shows, and their packages installed. The Angular one installs with
# --legacy-peer-deps, which works round a crash in this npm's resolver on that
# dependency tree and changes nothing that is built. The planner is not touched.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

quiet '~' 'rm -rf ~/compare && mkdir ~/compare'
for f in svelte vue react angular; do
  bash "$LAB_SH" script "cp -r $(cd ../../lab/compare && pwd)/$f ~/compare/$f" || true
done
shown four-counters.md src/Counter.svelte '~/compare/svelte/src/Counter.svelte'
shown four-counters.md src/Counter.vue '~/compare/vue/src/Counter.vue'
shown four-counters.md src/Counter.jsx '~/compare/react/src/Counter.jsx'
shown four-counters.md src/app/app.ts '~/compare/angular/src/app/app.ts'
for f in svelte vue react; do quiet "~/compare/$f" 'npm install'; done
quiet '~/compare/angular' 'npm install --legacy-peer-deps'

block svelte
session '~/compare/svelte' "npm run build 2>&1 | grep -E 'dist/assets'"
block vue
session '~/compare/vue' "npm run build 2>&1 | grep -E 'dist/assets'"
block react
session '~/compare/react' "npm run build 2>&1 | grep -E 'dist/assets'"
block angular
session '~/compare/angular' "npm run build 2>&1 | grep -E 'main-|Initial total'"
