#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of vue, as a script that produces
# them. Its output is pasted into the lesson by lab/fill.py and not committed.
#
#   sudo bash captures.sh > /tmp/l16.txt && for f in *.md; do python3 ../../lab/fill.py $f /tmp/l16.txt; done
#
# Starts from the planner and the sandbox as lesson 15 left them. Installs
# typescript 6.0.3, vue-tsc 3.3.13 and @vue/tsconfig 0.9.1 from the npm
# registry, in both. The two tsconfig.json files are the json fences of
# adding-typescript.md and generic-components.md; planner.ts, CourseCard and
# SessionRow are taken whole out of typed-props.md; the other changes typed-refs.md
# lists are applied with python as a person would type them.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
. ../../lab/lib.sh
S='~/vue/sandbox'
json() {  # json MD DEST: the first json fence of MD, saved as ana at DEST
  python3 -c "import re,sys;print(re.findall(r'^\`\`\`json\n(.*?)^\`\`\`', open('$1').read(), re.S|re.M)[0], end='')" |
    bash "$LAB_SH" script "cat > $2"
}
convert() {  # the planner's renames, as adding-typescript.md types them
  quiet $P 'for f in $(find src -name "*.js"); do mv "$f" "${f%.js}.ts"; done;
    sed -i "s#/src/main.js#/src/main.ts#" index.html;
    sed -i "s/<script setup>/<script setup lang=\"ts\">/" $(find src -name "*.vue")'
}
typed() {  # every fix of typed-props.md and typed-refs.md
  shown typed-props.md src/planner.ts $P/src/planner.ts
  shown typed-props.md src/components/CourseCard.vue $P/src/components/CourseCard.vue
  shown typed-props.md src/components/SessionRow.vue $P/src/components/SessionRow.vue
  bash "$LAB_SH" script "cd ~/vue/planner && python3 -" <<'PY'
def edit(path, pairs):
    s = open('src/' + path).read()
    for a, b in pairs:
        if b not in s:
            s = s.replace(a, b)
    open('src/' + path, 'w').write(s)
edit('stores/planner.ts', [
    ("import { toggleDone, addSession } from '../planner.js'", "import { toggleDone, addSession, type Course, type Session } from '../planner.js'"),
    ("// src/stores/planner.js", "// src/stores/planner.ts"),
    ("  const courses = ref([])\n  const sessions = ref([])", "  const courses = ref<Course[]>([])\n  const sessions = ref<Session[]>([])"),
    ("computed(() => (id) => courses", "computed(() => (id: string) => courses"),
    ("  let loading = null\n", "  let loading: Promise<void> | null = null\n"),
    ("  function toggle(id) {", "  function toggle(id: string) {"),
    ("  function add(session) {", "  function add(session: Omit<Session, 'id' | 'done'>) {")])
edit('composables/useToday.ts', [
    ("// src/composables/useToday.js", "// src/composables/useToday.ts"),
    ("  let timer\n", "  let timer: ReturnType<typeof setInterval> | undefined\n")])
edit('router.ts', [
    ("// src/router.js", "// src/router.ts"),
    ("import { createRouter, createWebHistory } from 'vue-router'", "import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'"),
    ("const routes = [", "const routes: RouteRecordRaw[] = ["),
    ("planner.hasCourse(to.params.id)", "planner.hasCourse(String(to.params.id))")])
edit('components/PlannerDialog.vue', [
    ("const dialog = useTemplateRef('dialog')", "const dialog = useTemplateRef<HTMLDialogElement>('dialog')"),
    ("dialog.value.showModal()", "dialog.value?.showModal()"), ("dialog.value.close()", "dialog.value?.close()")])
edit('components/SessionForm.vue', [
    ("const courseField = useTemplateRef('course')", "const courseField = useTemplateRef<HTMLSelectElement>('course')"),
    ("courseField.value.focus()", "courseField.value?.focus()"),
    ("const errors = computed(() => ({", "type Errors = Record<'course' | 'date' | 'minutes', string>\n\nconst errors = computed<Errors>(() => ({"),
    ("const shown = computed(() => (tried.value ? errors.value : {}))", "const shown = computed<Partial<Errors>>(() => (tried.value ? errors.value : {}))")])
edit('views/HomeView.vue', [
    ("const adding = useTemplateRef('adding')", "const adding = useTemplateRef<InstanceType<typeof PlannerDialog>>('adding')"),
    ("function onAdded(message) {", "function onAdded(message: string) {"),
    ("  adding.value.close()", "  adding.value?.close()"),
    ('@click="adding.open()"', '@click="adding?.open()"')])
PY
}
files() {
  quiet $P 'grep -q vue-tsc package.json || npm install --silent --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1'
  quiet $S 'grep -q vue-tsc package.json || npm install --silent --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1'
  json adding-typescript.md '~/vue/planner/tsconfig.json'
  json generic-components.md '~/vue/sandbox/tsconfig.json'
  quiet '~/vue' "for d in planner sandbox; do echo '/// <reference types=\"vite/client\" />' > \$d/env.d.ts; done"
  quiet $P "npm pkg set scripts.type-check='vue-tsc --noEmit' && npm pkg set scripts.build='vue-tsc --noEmit && vite build'"
  [ -f /home/ana/vue/planner/src/main.ts ] || convert
  typed
  local d
  for d in TypedList TypedPicker TypedMistakes; do shown generic-components.md src/demos/$d.vue $S/src/demos/$d.vue; done
}
if [ -n "${FILES_ONLY:-}" ]; then files; return 0; fi

start_from le-xjpgxv9m
block install
session $P 'npm install --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1'
json adding-typescript.md '~/vue/planner/tsconfig.json'
block env
session $P "echo '/// <reference types=\"vite/client\" />' > env.d.ts"
block script
session $P "npm pkg set scripts.type-check='vue-tsc --noEmit'"
block rename
session $P "for f in \$(find src -name '*.js'); do mv \"\$f\" \"\${f%.js}.ts\"; done" \
  "sed -i 's#/src/main.js#/src/main.ts#' index.html" \
  "sed -i 's/<script setup>/<script setup lang=\"ts\">/' \$(find src -name '*.vue')"
block count
session $P "npm run type-check 2>&1 | grep -c 'error TS'"
block first
session $P "npm run type-check 2>&1 | grep -o 'error TS[0-9]*' | sort | uniq -c | sort -rn"
typed
block typo
session $P "sed -i \"s/emit('toggle'/emit('toggel'/\" src/components/SessionRow.vue" 'npm run type-check'
block typo-back
session $P "sed -i \"s/emit('toggel'/emit('toggle'/\" src/components/SessionRow.vue"
block clean
session $P 'npm run type-check'

block sandbox-ts
session $S 'npm install --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1'
json generic-components.md '~/vue/sandbox/tsconfig.json'
quiet $S "echo '/// <reference types=\"vite/client\" />' > env.d.ts"
for d in TypedList TypedPicker TypedMistakes; do shown generic-components.md src/demos/$d.vue $S/src/demos/$d.vue; done
dev sb $S 'npm run dev' 5173
block picker
session $S "look 'http://localhost:5173/?demo=TypedPicker' --do 'click text=Spanish' --text '#chosen'"
block mistakes
session $S "look 'http://localhost:5173/?demo=TypedMistakes'"
bg_stop sb
block sandbox-check
session $S 'npx vue-tsc --noEmit'

block build-script
session $P "npm pkg set scripts.build='vue-tsc --noEmit && vite build'"
block vue-tsc/build-fails
session $P "sed -i \"s/emit('toggle'/emit('toggel'/\" src/components/SessionRow.vue" 'npm run build' \
  "sed -i \"s/emit('toggel'/emit('toggle'/\" src/components/SessionRow.vue"
dev pl $P 'npm run dev' 5173
block dev
session $P 'look http://localhost:5173/ --clock 2026-10-21T10:00 --text main'
bg_stop pl
block time
session $P 'time npm run type-check'
block du
session $P 'du -sh node_modules' 'du -sh node_modules/typescript'
snapshot
