---
title: The planner's composables
version: 1
---

**The planner's `App.vue` hands two of its jobs to composables: loading and saving the data, and keeping
today's date.** What is left in `App` is what only `App` can decide: which week is shown, what the
screen is made of, and what a tick means. Nothing on the screen changes.

## useToday

Lesson 9's clock, moved out of `App` with its start and its stop:

```javascript
// src/composables/useToday.js: today's date, kept current while the page is open.
import { ref, onMounted, onUnmounted } from 'vue'
import { isoDate } from '../planner.js'

export function useToday() {
  const today = ref(isoDate(new Date()))
  let timer
  onMounted(() => {
    timer = setInterval(() => {
      today.value = isoDate(new Date())
    }, 60_000)
  })
  onUnmounted(() => clearInterval(timer))
  return today
}
```

## usePlannerData

Lesson 2's loading and lesson 4's saving, together, because they are one job: where the planner's data
comes from and where it goes.

```javascript
// src/composables/usePlannerData.js: the courses and the sessions, loaded from
// courses.json, with the sessions kept in this browser from then on.
import { ref, watch } from 'vue'

const STORAGE_KEY = 'planner.sessions'

export function usePlannerData() {
  const courses = ref([])
  const sessions = ref([])
  const error = ref('')
  const source = ref('')

  fetch('/courses.json')
    .then((response) => {
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)
      return response.json()
    })
    .then((data) => {
      courses.value = data.courses
      const saved = localStorage.getItem(STORAGE_KEY)
      sessions.value = saved ? JSON.parse(saved) : data.sessions
      source.value = saved ? 'this browser' : 'courses.json'
    })
    .catch((e) => {
      error.value = `Could not load the courses: ${e.message}`
    })

  watch(sessions, (list) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list))
  })

  return { courses, sessions, error, source }
}
```

## App, whole

The whole file, since enough of it has changed in the last three lessons to be worth reading in one
piece again:

```html
<!-- src/App.vue -->
<script setup>
import { ref, computed, provide } from 'vue'
import AppFooter from './components/AppFooter.vue'
import CourseCard from './components/CourseCard.vue'
import SessionRow from './components/SessionRow.vue'
import PlannerPanel from './components/PlannerPanel.vue'
import { titlesKey } from './keys.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'
import { usePlannerData } from './composables/usePlannerData.js'
import { useToday } from './composables/useToday.js'

const title = 'Study planner'
const { courses, sessions, error, source } = usePlannerData()
const today = useToday()
const monday = ref(weekStart(new Date()))

const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
const titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))
provide(titlesKey, titles)

function toggle(id) {
  sessions.value = toggleDone(sessions.value, id)
}

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
  <header>
    <h1>{{ title }}</h1>
    <p v-if="error" role="alert">{{ error }}</p>
    <p v-else-if="courses.length === 0">Loading…</p>
    <p v-if="source">{{ sessions.length }} sessions, read from {{ source }}</p>
  </header>
  <main>
    <PlannerPanel title="Courses">
      <ul>
        <CourseCard
          v-for="course in perCourse"
          :key="course.id"
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
  </main>
  <AppFooter />
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
</style>
```

Tick the guitar session and load the page again, as lesson 5 did:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text("Guitar") input' --do 'goto /'
[vite] connecting...
[vite] connected.
-- check label:has-text("Guitar") input
-- goto /
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

6 sessions, read from this browser

Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

20 of 20 minutes done, goal 90

 22% of the weekly goal

Week of 19 October 2026
Previous weekNext week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
95 of 195 minutes done

Built with Vue 3.5.44
```

**Everything the earlier lessons built still works**: the tick was saved and read back from the
browser, today's session is marked, the totals follow. `App.vue`'s script lost its `fetch`, its watcher,
its storage key, its timer and both hooks, and gained two lines that say what it uses.

## Where this stops working

`usePlannerData` is a composable, so every call makes a new copy of the data and fetches it again. Today
only `App` calls it, and that is fine. The day a second component needs the sessions, the course page
of lesson 12 for instance, calling `usePlannerData()` there would give it a separate list. A tick on one
screen would not appear on the other until a reload, and the two watchers would overwrite each other's
copy in storage. **Shared state needs one owner**, and lesson 13 gives the planner one, with a store.
