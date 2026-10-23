---
title: Routes, RouterView and RouterLink
version: 1
---

**A route pairs a path with a component; `<RouterView>` is where the matched component is drawn; and
`<RouterLink>` is a link that changes the address without reloading the page.** Those three are the
whole idea, and every other feature of the router is a refinement of one of them.

The planner's routes, in their final form for this lesson. The notes say which section explains each
part:

```schooling-example
{"language": "javascript", "file": "src/router.js", "parts": [
 {"code": "import { createRouter, createWebHistory } from 'vue-router'\nimport HomeView from './views/HomeView.vue'\nimport NotFound from './views/NotFound.vue'", "note": "The router is made from a list of routes and a history, which is how addresses are written. `createWebHistory` gives real paths, `/courses/spanish`; the last section of this lesson is about it."},
 {"code": "// Asks the data file whether a course exists. Lesson 13 replaces this with the store.\nasync function courseExists(id) {\n  const response = await fetch('/courses.json')\n  const { courses } = await response.json()\n  return courses.some((course) => course.id === id)\n}", "note": "A guard's helper: it asks the data file whether a course exists. The section on guards explains why, and lesson 13 replaces it."},
 {"code": "const routes = [\n  { path: '/', name: 'home', component: HomeView, meta: { title: 'Study planner' } },", "note": "The week, at `/`. `name` lets code and links refer to a route without spelling its path; `meta` is free-form data the guards read."},
 {"code": "  {\n    path: '/courses/:id',\n    // Loaded only when somebody opens a course: a separate file in the build.\n    component: () => import('./views/CourseView.vue'),\n    props: true,", "note": "A course. `:id` is a parameter: it matches any one segment and hands it over, as a prop because of `props: true`. The section on parameters."},
 {"code": "    beforeEnter: async (to) => {\n      if (!(await courseExists(to.params.id))) {\n        return { name: 'not-found', params: { pathMatch: to.path.slice(1).split('/') } }\n      }\n    },", "note": "A guard that runs before entering this route, and sends an unknown course to the page for unknown addresses."},
 {"code": "    children: [\n      { path: '', name: 'course-week', component: () => import('./views/CourseWeek.vue') },\n      { path: 'all', name: 'course-all', component: () => import('./views/CourseAll.vue') },\n    ],\n    meta: { title: 'Course' },\n  },", "note": "Two child routes, drawn inside the course's page: the course's week at `/courses/spanish`, and every session at `/courses/spanish/all`. The section on nested routes."},
 {"code": "  { path: '/:pathMatch(.*)*', name: 'not-found', component: NotFound, meta: { title: 'Not found' } },\n]\n\nexport const router = createRouter({\n  history: createWebHistory(),\n  routes,\n})", "note": "Anything else. `(.*)*` matches every path. Its place in the list does not matter, because the router ranks routes by how specific they are and tries the most specific first; it is written last because that is where a reader looks for it."},
 {"code": "// After every navigation that happened, the tab says where the student is.\nrouter.afterEach((to, from, failure) => {\n  if (!failure) document.title = `${to.meta.title} · Study planner`\n})", "note": "After every navigation, the tab's title names the page, unless a guard cancelled or redirected it: the third argument says so. A title is how the tab, the history and a bookmark name the page."}
]}
```

## The pages are components

A component a route draws is called a **view**, and views live in `src/views`, apart from the reusable
pieces in `src/components`. The week that used to be the body of `App.vue` is now the first view, with
its own title:

```html
<!-- src/views/HomeView.vue -->
<script setup>
import { ref, computed, inject } from 'vue'
import CourseCard from '../components/CourseCard.vue'
import SessionRow from '../components/SessionRow.vue'
import PlannerPanel from '../components/PlannerPanel.vue'
import { plannerKey } from '../keys.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek } from '../planner.js'

const { courses, sessions, today, toggle } = inject(plannerKey)
const monday = ref(weekStart(new Date()))

const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
const perCourse = computed(() =>
  courses.value.map((course) => ({
    ...course,
    ...weekTotal(
      sessions.value.filter((s) => s.course === course.id),
      monday.value,
    ),
  })),
)
const total = computed(() => weekTotal(sessions.value, monday.value))
</script>

<template>
  <h1>This week</h1>
  <PlannerPanel title="Courses">
    <ul>
      <CourseCard
        v-for="course in perCourse"
        :key="course.id"
        :id="course.id"
        :title="course.title"
        :goal="course.goal"
        :planned="course.planned"
        :done="course.done"
      />
    </ul>
  </PlannerPanel>
  <PlannerPanel :title="`Week of ${formatDay(monday)}`">
    <template #actions>
      <nav aria-label="Weeks">
        <button @click="monday = addDays(monday, -7)">Previous week</button>
        <button @click="monday = addDays(monday, 7)">Next week</button>
      </nav>
    </template>
    <ul v-if="thisWeek.length > 0">
      <SessionRow
        v-for="session in thisWeek"
        :key="session.id"
        :session="session"
        :today="session.date === today"
        @toggle="toggle"
      />
    </ul>
    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>
  </PlannerPanel>
</template>
```

It reads the planner's data with `inject`, from `App`, which still owns it. Lesson 8 said that state
shared by several pages belongs in a store; until lesson 13 builds one, `App` provides the data under a
second key, `plannerKey`, added beside `titlesKey` in `src/keys.js`:

```javascript
// src/keys.js: the keys the planner provides values under. A Symbol is unique,
// so no other code can provide or inject under the same key by accident.
export const titlesKey = Symbol('course titles')
export const plannerKey = Symbol('planner data')
```

And `App.vue` becomes the frame around whatever the router draws:

```html
<!-- src/App.vue -->
<script setup>
import { computed, provide } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import AppFooter from './components/AppFooter.vue'
import { titlesKey, plannerKey } from './keys.js'
import { toggleDone } from './planner.js'
import { usePlannerData } from './composables/usePlannerData.js'
import { useToday } from './composables/useToday.js'

const { courses, sessions, error, source } = usePlannerData()
const today = useToday()

const titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))
provide(titlesKey, titles)

function toggle(id) {
  sessions.value = toggleDone(sessions.value, id)
}
// Every view reads the data from here, until lesson 13 gives it a store.
provide(plannerKey, { courses, sessions, today, toggle })
</script>

<template>
  <header>
    <p class="brand"><RouterLink to="/">Study planner</RouterLink></p>
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="courses.length === 0">Loading…</p>
    <p v-if="source">{{ sessions.length }} sessions, read from {{ source }}</p>
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

**`<RouterView />` is where the views go.** Everything around it, the header with a link home and the
footer, is drawn on every page. The header's title is now a `<p>`, because each view has its own `<h1>`
and a page should have one.

The cards link to their course. `CourseCard` gains an `id` prop and a `<RouterLink>` around its title:

```html
<!-- src/components/CourseCard.vue -->
<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

// Destructured, and still reactive: the compiler turns every use of `done`
// below into `props.done`.
const { id, title, goal, planned, done } = defineProps({
  id: { type: String, required: true },
  title: { type: String, required: true },
  goal: { type: Number, required: true },
  planned: { type: Number, default: 0 },
  done: { type: Number, default: 0 },
})

const percent = computed(() => Math.round((done / goal) * 100))
</script>

<template>
  <li class="card">
    <h3><RouterLink :to="`/courses/${id}`">{{ title }}</RouterLink></h3>
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

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text main
[vite] connecting...
[vite] connected.
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

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
75 of 195 minutes done
```

The same week as before, drawn by `HomeView` inside `App`'s `<RouterView>`.

## RouterLink, not a

`<RouterLink to="/courses/spanish">` draws an ordinary `<a href="/courses/spanish">`, so it can be
opened in a new tab, copied and read by a screen reader as a link. What it adds is a click handler that
stops the browser from loading the address, and asks the router to change the screen instead. A plain
`<a>` would work too, and reload the whole application on every click, losing every ref that was not
saved.
