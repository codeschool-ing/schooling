---
title: The planner's store
version: 1
---

**The planner's data moves into one store, `usePlannerStore`, and every part of the application reads
it from there: `App`, the three views, the session rows, and the router's guard.** Two things go away
with it, `usePlannerData` and the two keys `App` provided in lessons 8 and 12. Nothing on the screen
changes, except that the course page and the week now share one list of sessions without anybody
passing it around.

Stop the dev server, install Pinia in the planner, pinned, and start it again:

```
ana@dev:~/vue/planner$ npm install --save-exact pinia@4.1.0

added 1 package, and audited 82 packages in 671ms

24 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## The store, installed

The store itself is the one the second section of this lesson walked through; save it as
`src/stores/planner.js`. `main.js` installs Pinia, **before the router**:

```javascript
// src/main.js
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router.js'
import './main.css'

// Pinia first, so that anything installed after it may use a store.
createApp(App).use(createPinia()).use(router).mount('#app')
```

Here either order would work: the router starts its first navigation when it is installed, but runs the
guards a moment later, by which time Pinia is installed whichever came first. Pinia first is the habit
worth keeping anyway, because a plugin that uses a store while it is being installed finds the
store only if Pinia is already there.

## The guard asks the store

`router.js` loses `courseExists`, and the guard becomes:

```javascript
beforeEnter: async (to) => {
  const planner = usePlannerStore()
  await planner.load()
  if (!planner.hasCourse(to.params.id)) {
    return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') } }
  }
},
```

with `import { usePlannerStore } from './stores/planner.js'` at the top. `load()` returns the same
promise to every caller, so the guard and `App` share one request: whichever asks first sends it, and the
other waits for the same answer.

## App, and the views

`App.vue` no longer owns the data; it starts the load and draws the frame:

```html
<!-- src/App.vue -->
<script setup>
import { RouterLink, RouterView } from 'vue-router'
import AppFooter from './components/AppFooter.vue'
import { usePlannerStore } from './stores/planner.js'

const planner = usePlannerStore()
planner.load()
</script>

<template>
  <header>
    <p class="brand"><RouterLink to="/">Study planner</RouterLink></p>
    <p v-if="planner.error" role="alert">{{ planner.error }}</p>
    <p v-else-if="planner.courses.length === 0">Loading…</p>
    <p v-if="planner.source">{{ planner.sessions.length }} sessions, read from {{ planner.source }}</p>
  </header>
  <main>
    <RouterView />
  </main>
  <AppFooter />
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
.brand {
  font-size: 1.5rem;
  font-weight: 700;
}
</style>
```

Each view swaps its `inject(plannerKey)` line for the store, and gets `today` from lesson 10's
`useToday` itself. `HomeView.vue`'s script now begins:

```javascript
import { ref, computed } from 'vue'
import CourseCard from '../components/CourseCard.vue'
import SessionRow from '../components/SessionRow.vue'
import PlannerPanel from '../components/PlannerPanel.vue'
import { storeToRefs } from 'pinia'
import { usePlannerStore } from '../stores/planner.js'
import { useToday } from '../composables/useToday.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek } from '../planner.js'

const planner = usePlannerStore()
const { courses, sessions } = storeToRefs(planner)
const { toggle } = planner
const today = useToday()
```

and the rest of it is unchanged. `CourseWeek.vue` and `CourseAll.vue` make the same swap, with
`const { sessions } = storeToRefs(planner)`, and `CourseView.vue` takes only `courses`. `SessionRow`
reads the course titles from the store instead of injecting them:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { computed } from 'vue'
import { formatDay } from '../planner.js'
import { usePlannerStore } from '../stores/planner.js'

const { session, today } = defineProps({
  session: { type: Object, required: true },
  today: { type: Boolean, default: false },
})
const emit = defineEmits(['toggle'])

// The course's title, from the store; its id until the courses have loaded.
const planner = usePlannerStore()
const title = computed(() => planner.titles[session.course] ?? session.course)
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

Delete `src/keys.js` and `src/composables/usePlannerData.js`; nothing imports them any more.

## One list, every page

Open the week, go to Spanish, tick its session of the 23rd, and come back:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --do 'check label:has-text("23 October") input' --do 'click text=Study planner' --text main --network
net  GET /  200
net  GET /src/main.js  200
net  GET /node_modules/.vite/deps/vue.js?v=cadb1fb2  200
net  GET /node_modules/.vite/deps/pinia.js?v=23a4d815  200
net  GET /src/main.css  200
net  GET /src/router.js  200
net  GET /src/App.vue  200
net  GET /node_modules/.vite/deps/vue.runtime.esm-bundler-CWNVreLk.js?v=d459ded8  200
net  GET /node_modules/.vite/deps/dist-BZygRcNR.js?v=d459ded8  200
net  GET /@vite/client  200
net  GET /node_modules/.vite/deps/vue-router.js?v=4d308e57  200
net  GET /src/App.vue?vue&type=style&index=0&scoped=7a7a37b1&lang.css  200
net  GET /@id/__x00__plugin-vue:export-helper  200
net  GET /src/stores/planner.js  200
net  GET /src/views/NotFound.vue  200
net  GET /src/views/HomeView.vue  200
net  GET /src/components/AppFooter.vue  200
net  GET /node_modules/vite/dist/client/env.mjs  200
[vite] connecting...
net  GET /src/planner.js  200
net  GET /src/components/AppFooter.vue?vue&type=style&index=0&scoped=6704560a&lang.css  200
net  GET /src/composables/useToday.js  200
[vite] connected.
net  GET /src/components/CourseCard.vue  200
net  GET /src/components/PlannerPanel.vue  200
net  GET /src/components/SessionRow.vue  200
net  GET /src/components/CourseCard.vue?vue&type=style&index=0&scoped=a191423e&lang.css  200
net  GET /src/components/PlannerPanel.vue?vue&type=style&index=0&scoped=0710be83&lang.css  200
net  GET /src/components/SessionRow.vue?vue&type=style&index=0&scoped=b7ae2f26&lang.css  200
net  GET /courses.json  200
-- click text=Spanish >> nth=0
net  GET /src/views/CourseView.vue  200
net  GET /src/views/CourseWeek.vue  200
net  GET /src/views/CourseView.vue?vue&type=style&index=0&scoped=62175599&lang.css  200
-- check label:has-text("23 October") input
-- click text=Study planner
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

70 of 70 minutes done, goal 120

 58% of the weekly goal

Guitar

0 of 20 minutes done, goal 90

 0% of the weekly goal

Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
115 of 195 minutes done
```

**Spanish is now 70 of 70 on the week's page**, ticked on the course's page: the two pages are two
views of one store. And the network list has **one** request for `courses.json`, against two in lesson
12, where the guard fetched its own copy.
