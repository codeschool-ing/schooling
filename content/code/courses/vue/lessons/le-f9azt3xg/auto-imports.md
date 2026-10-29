---
title: Auto-imports, and the planner's parts brought over
version: 1
---

**In a Nuxt project, a component in `app/components/` may be used by any template, and a function
exported from `app/composables/`, `app/utils/` or `shared/utils/` may be called by any script, all
without an `import`.** Nuxt's own functions, `useRoute`, `useFetch`, `navigateTo`, and Vue's,
`ref`, `computed`, `watch`, are imported the same way. The planner's parts come over now, and they
lose lines rather than gain them.

`planner.ts`, the rules lesson 3 wrote and lesson 16 typed, goes to `shared/utils/`, the folder whose
exports both the app and the server get, because the server will need `toggleDone` in the next
section. Its first line names its old place, so `sed` corrects it. The stylesheet and the data come
too:

```
ana@dev:~/vue/planner-nuxt$ mkdir -p shared/utils app/components app/assets server/data
ana@dev:~/vue/planner-nuxt$ cp ../planner/src/planner.ts shared/utils/planner.ts
ana@dev:~/vue/planner-nuxt$ sed -i '1s#src/planner.ts#shared/utils/planner.ts#' shared/utils/planner.ts
ana@dev:~/vue/planner-nuxt$ cp ../planner/src/main.css app/assets/main.css
ana@dev:~/vue/planner-nuxt$ cp ../planner/public/courses.json server/data/courses.json
```

Nothing in `planner.ts` changes: its functions take plain values and know nothing of Vue, which was
the point of writing them that way in lesson 3.

## Three components, with fewer lines

`PlannerPanel` comes over as it is, with its first comment saying where it now lives:

```html
<!-- app/components/PlannerPanel.vue -->
<script setup lang="ts">
defineProps({ title: { type: String, required: true } })
</script>

<template>
  <section class="panel">
    <header class="panel-head">
      <h2>{{ title }}</h2>
      <slot name="actions" />
    </header>
    <slot>
      <p>Nothing here yet.</p>
    </slot>
    <footer v-if="$slots.footer" class="panel-foot">
      <slot name="footer" />
    </footer>
  </section>
</template>

<style scoped>
.panel {
  border: 1px solid #c9d8cf;
  border-radius: 6px;
  margin: 1rem 0;
  padding: 0 1rem 1rem;
}
.panel-head {
  align-items: center;
  display: flex;
  gap: 1rem;
  justify-content: space-between;
}
.panel-foot {
  border-top: 1px solid #c9d8cf;
  color: #2f6f4e;
  padding-top: 0.5rem;
}
</style>
```

`CourseCard` loses its two `import` lines, and `RouterLink` becomes `NuxtLink`:

```html
<!-- app/components/CourseCard.vue -->
<script setup lang="ts">
// Destructured, and still reactive: the compiler turns every use of `done`
// below into `props.done`.
const {
  id,
  title,
  goal,
  planned = 0,
  done = 0,
} = defineProps<{
  id: string
  title: string
  goal: number // minutes a week
  planned?: number
  done?: number
}>()

const percent = computed(() => Math.round((done / goal) * 100))
</script>

<template>
  <li class="card">
    <h3><NuxtLink :to="`/courses/${id}`">{{ title }}</NuxtLink></h3>
    <p>{{ done }} of {{ planned }} minutes done, goal {{ goal }}</p>
    <p>
      <progress :value="done" :max="goal">{{ percent }}%</progress>
      {{ percent }}% of the weekly goal
    </p>
  </li>
</template>

<style scoped>
.card {
  margin-bottom: 1rem;
}
p {
  color: #2f6f4e;
}
</style>
```

`SessionRow` changes more, because it read the course titles from the Pinia store of lesson 13, and
this project has no store. The title becomes a prop, given by the page that has the data:

```html
<!-- app/components/SessionRow.vue -->
<script setup lang="ts">
const { session, title, today = false } = defineProps<{
  session: Session
  title: string
  today?: boolean
}>()
const emit = defineEmits<{
  toggle: [id: string]
}>()
</script>

<template>
  <li :class="{ done: session.done, today }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
      <strong v-if="today">(today)</strong>
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
.today {
  background: #e6f0ea;
}
</style>
```

`Session`, a type, and `formatDay`, a function, both come from `shared/utils/planner.ts` without
being named anywhere in the file.

## Where the names come from

An import you do not write still has to exist somewhere, and Nuxt writes it, into `.nuxt`, the folder
of generated files it keeps up to date while the dev server runs:

```
ana@dev:~/vue/planner-nuxt$ grep -n 'shared/utils/planner' .nuxt/imports.d.ts .nuxt/types/imports.d.ts | cut -c1-140
.nuxt/imports.d.ts:37:export { isoDate, addDays, weekStart, formatDay, sessionsInWeek, weekTotal, addSession, toggleDone, Course, Session, T
.nuxt/types/imports.d.ts:6:  const addDays: typeof import('../../shared/utils/planner').addDays
.nuxt/types/imports.d.ts:8:  const addSession: typeof import('../../shared/utils/planner').addSession
.nuxt/types/imports.d.ts:35:  const formatDay: typeof import('../../shared/utils/planner').formatDay
.nuxt/types/imports.d.ts:53:  const isoDate: typeof import('../../shared/utils/planner').isoDate
.nuxt/types/imports.d.ts:91:  const sessionsInWeek: typeof import('../../shared/utils/planner').sessionsInWeek
.nuxt/types/imports.d.ts:103:  const toggleDone: typeof import('../../shared/utils/planner').toggleDone
.nuxt/types/imports.d.ts:197:  const weekStart: typeof import('../../shared/utils/planner').weekStart
.nuxt/types/imports.d.ts:198:  const weekTotal: typeof import('../../shared/utils/planner').weekTotal
.nuxt/types/imports.d.ts:218:  export type { Course, Session, Totals } from '../../shared/utils/planner'
.nuxt/types/imports.d.ts:219:  import('../../shared/utils/planner')
.nuxt/types/imports.d.ts:227:    readonly addDays: UnwrapRef<typeof import('../../shared/utils/planner')['addDays']>
.nuxt/types/imports.d.ts:229:    readonly addSession: UnwrapRef<typeof import('../../shared/utils/planner')['addSession']>
.nuxt/types/imports.d.ts:256:    readonly formatDay: UnwrapRef<typeof import('../../shared/utils/planner')['formatDay']>
.nuxt/types/imports.d.ts:274:    readonly isoDate: UnwrapRef<typeof import('../../shared/utils/planner')['isoDate']>
.nuxt/types/imports.d.ts:312:    readonly sessionsInWeek: UnwrapRef<typeof import('../../shared/utils/planner')['sessionsInWeek']>
.nuxt/types/imports.d.ts:324:    readonly toggleDone: UnwrapRef<typeof import('../../shared/utils/planner')['toggleDone']>
.nuxt/types/imports.d.ts:418:    readonly weekStart: UnwrapRef<typeof import('../../shared/utils/planner')['weekStart']>
.nuxt/types/imports.d.ts:419:    readonly weekTotal: UnwrapRef<typeof import('../../shared/utils/planner')['weekTotal']>
```

**Every export of `planner.ts` is listed, the types among them**, and that file is what the editor and
`vue-tsc` read to know what `formatDay` is. The components are listed in `.nuxt/components.d.ts` the
same way, each of them twice:

```
ana@dev:~/vue/planner-nuxt$ grep -n '"../app/components' .nuxt/components.d.ts | cut -c1-120
17:export const CourseCard: typeof import("../app/components/CourseCard.vue")['default']
18:export const PlannerPanel: typeof import("../app/components/PlannerPanel.vue")['default']
19:export const SessionRow: typeof import("../app/components/SessionRow.vue")['default']
114:export const LazyCourseCard: LazyComponent<typeof import("../app/components/CourseCard.vue")['default']>
115:export const LazyPlannerPanel: LazyComponent<typeof import("../app/components/PlannerPanel.vue")['default']>
116:export const LazySessionRow: LazyComponent<typeof import("../app/components/SessionRow.vue")['default']>
```

The second name of each is the first with `Lazy` in front of it. `<LazyCourseCard>` is the same
component loaded only when it is first drawn, in a chunk of its own, like lesson 12's lazy routes; it
is worth it for something large that most visits never show, and the planner has nothing like that.

A component in a subfolder takes the folder into its name: `components/week/Row.vue` would be
`<WeekRow>`. And the build includes only what is used: a component nobody draws, or a function
nobody calls, is in the list and not in the bundle.

The cost is the one every convention has. Reading a file no longer tells you where a name comes from,
so a function called `formatDay` in `shared/utils` and another `formatDay` in `app/utils` would be a
collision Nuxt warns about at start-up. A teammate meeting `toggleDone` for the first time needs
the editor's *go to definition*, or the generated file above. An explicit `import { formatDay } from
'#imports'` still works, wherever a file reads better with one.
