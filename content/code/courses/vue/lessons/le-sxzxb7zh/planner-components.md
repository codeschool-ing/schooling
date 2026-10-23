---
title: The planner, in components
version: 1
---

**The planner's list items become two components, `CourseCard` and `SessionRow`, and `App.vue` goes back
to owning the state and arranging the pieces.** Nothing on the screen changes except a progress bar per
course. What changes is that each piece now has a contract, and can be read, changed and tested on its
own.

## CourseCard

A card is given a title and three numbers, and draws them. It owns nothing:

```html
<!-- src/components/CourseCard.vue -->
<script setup>
import { computed } from 'vue'

// Destructured, and still reactive: the compiler turns every use of `done`
// below into `props.done`.
const { title, goal, planned, done } = defineProps({
  title: { type: String, required: true },
  goal: { type: Number, required: true },
  planned: { type: Number, default: 0 },
  done: { type: Number, default: 0 },
})

const percent = computed(() => Math.round((done / goal) * 100))
</script>

<template>
  <li class="card">
    <h2>{{ title }}</h2>
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

The props are destructured, which since Vue 3.5 keeps them reactive (the first section of this lesson),
so `percent` follows `done`. A `<progress>` element is the browser's own progress bar, announced by a
screen reader with its value; the text inside it is what a browser with no support for it would show.

## SessionRow

A row is given a session and its course's title, and reports a tick:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { formatDay } from '../planner.js'

defineProps({
  session: { type: Object, required: true },
  title: { type: String, required: true },
})
const emit = defineEmits(['toggle'])
</script>

<template>
  <li :class="{ done: session.done }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
</style>
```

**It emits `toggle` with the session's id and does nothing else.** It does not import `toggleDone`, and
it has no idea that a list exists, that it is saved, or that a total depends on it. That is the
contract of the last sections, applied: the row reports, `App` decides.

The row's style for a session that is done moved here with the markup it styles, and left `App.vue`.

## App

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport CourseCard from './components/CourseCard.vue'\nimport SessionRow from './components/SessionRow.vue'", "note": "The two components are imported, and used as tags in the template."},
 {"code": "import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst thisWeek = computed(() =>\n  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),\n)\nconst titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))\n\nfunction toggle(id) {\n  sessions.value = toggleDone(sessions.value, id)\n}\n\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)\n\nconst STORAGE_KEY = 'planner.sessions'\n\nfetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n\n// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>\n\n<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>", "note": "The script is lesson 5's, unchanged: the state, the rules and `toggle` all stay here, with the data they belong to."},
 {"code": "  <main>\n    <ul class=\"courses\">\n      <CourseCard\n        v-for=\"course in perCourse\"\n        :key=\"course.id\"\n        :title=\"course.title\"\n        :goal=\"course.goal\"\n        :planned=\"course.planned\"\n        :done=\"course.done\"\n      />\n    </ul>", "note": "One `CourseCard` per course, each given its four values as props."},
 {"code": "    <h2>This week</h2>\n    <p v-if=\"thisWeek.length === 0\">Nothing planned this week.</p>\n    <ul v-else class=\"sessions\">\n      <SessionRow\n        v-for=\"session in thisWeek\"\n        :key=\"session.id\"\n        :session=\"session\"\n        :title=\"titles[session.course]\"\n        @toggle=\"toggle\"\n      />\n    </ul>\n  </main>\n  <AppFooter />\n</template>", "note": "One `SessionRow` per session. `@toggle=\"toggle\"` hands the emitted id straight to the same `toggle` function lesson 5 wrote."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses,\n.sessions {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "The style loses `.done`, which moved into `SessionRow`."}
]}
```

With the planner's server running, tick the guitar session:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text("Guitar") input' --text main
[vite] connecting...
[vite] connected.
-- check label:has-text("Guitar") input
== the text of main
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

20 of 20 minutes done, goal 90

 22% of the weekly goal

This week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

**Guitar went to 20 of 20 and 22% of the goal**: the row emitted, `App` replaced the list, `perCourse`
recomputed, and the card's `done` prop changed, so its `percent` followed. Three components took part,
and each one did only its own part.

## What App is now

`App.vue` holds the data, the rules and the arrangement. It is still the longest file in the planner,
and it will stay the place where state lives until lesson 13 moves the state into a store, at which
point `App` becomes the arrangement and nothing else. Lesson 7 gives the cards a shared frame with
slots, and lesson 8 lets a component deep in the tree reach the titles without them being passed down
level by level.
