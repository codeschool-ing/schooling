---
title: A panel for the planner
version: 1
---

**The planner gets one frame, `PlannerPanel`, with a title, a slot for actions beside it, a body and a
footer, and both halves of the screen are drawn in it.** It also gets a stylesheet of its own for the
things every component shares, which lesson 1 promised would arrive here.

## The panel

```html
<!-- src/components/PlannerPanel.vue -->
<script setup>
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

Every slot of this lesson is in it: a title as a prop, because it is only text; an `actions` slot,
because the week's buttons are markup; a default slot with a fallback; and a footer drawn only when the
parent fills it.

## The shared look

Rules that apply to the whole page do not belong to any one component, so they go in a plain stylesheet,
imported once by `main.js`:

```css
/* src/main.css: the planner's look, shared by every component. */
body {
  color: #1d2b24;
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  margin: 0 auto;
  max-width: 40rem;
  padding: 0 1rem;
}
ul {
  list-style: none;
  padding: 0;
}
button {
  font: inherit;
}
```

```javascript
// src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import './main.css'

createApp(App).mount('#app')
```

Importing a `.css` file from JavaScript is a Vite feature: in development it injects the rules into the
page, and lesson 17's build puts them in a file of their own. The rules are not scoped, which is the
point: `ul` loses its bullets everywhere, so `App.vue` no longer needs its own `.courses` and `.sessions`
rules.

## The cards, one level down

The panel's title is an `<h2>`, so the course cards inside it become `<h3>`s. Headings are how a
screen-reader user moves around a page, and a level that jumps or repeats makes that map wrong.
`CourseCard.vue` changes in that one line:

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
    <h3>{{ title }}</h3>
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

## App

The script is lesson 6's, with `PlannerPanel` imported beside the other components. The template and
the style change:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport CourseCard from './components/CourseCard.vue'\nimport SessionRow from './components/SessionRow.vue'\nimport PlannerPanel from './components/PlannerPanel.vue'\nimport { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst thisWeek = computed(() =>\n  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),\n)\nconst titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))\n\nfunction toggle(id) {\n  sessions.value = toggleDone(sessions.value, id)\n}\n\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)\n\nconst STORAGE_KEY = 'planner.sessions'\n\nfetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n\n// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>", "note": "The script: lesson 6's, plus one import."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n  </header>", "note": "The header keeps the title and where the sessions came from. The week line moved into the second panel's title."},
 {"code": "  <main>\n    <PlannerPanel title=\"Courses\">\n      <ul>\n        <CourseCard\n          v-for=\"course in perCourse\"\n          :key=\"course.id\"\n          :title=\"course.title\"\n          :goal=\"course.goal\"\n          :planned=\"course.planned\"\n          :done=\"course.done\"\n        />\n      </ul>\n    </PlannerPanel>", "note": "The first panel: only a title and a body."},
 {"code": "    <PlannerPanel :title=\"`Week of ${formatDay(monday)}`\">\n      <template #actions>\n        <nav aria-label=\"Weeks\">\n          <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n          <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n        </nav>\n      </template>", "note": "The second panel's title is the week, and its `actions` slot holds the two buttons, wrapped in a `<nav>` with a name so a screen reader can announce it."},
 {"code": "      <ul v-if=\"thisWeek.length > 0\">\n        <SessionRow\n          v-for=\"session in thisWeek\"\n          :key=\"session.id\"\n          :session=\"session\"\n          :title=\"titles[session.course]\"\n          @toggle=\"toggle\"\n        />\n      </ul>", "note": "The body is the list, drawn only when the week has sessions. When it has none, the slot's content is a `v-if` that came out false, which counts as empty, so the panel draws its fallback."},
 {"code": "      <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>\n    </PlannerPanel>\n  </main>\n  <AppFooter />\n</template>", "note": "The footer is the week's total."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\n</style>", "note": "What is left of the style is the header's rule. The list rules moved to `main.css`."}
]}
```

With the planner's server running:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

6 sessions, read from courses.json

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
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
75 of 195 minutes done

Built with Vue 3.5.44
```

And the week after, which has nothing planned:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --text 'main section:nth-child(2)'
[vite] connecting...
[vite] connected.
-- click text=Next week
== the text of main section:nth-child(2)
Week of 26 October 2026
Previous weekNext week

Nothing here yet.

0 of 0 minutes done
```

**The empty week drew the panel's fallback, `Nothing here yet.`**, and the footer still shows a total of
zero, because the footer was filled. Lesson 2's planner said "Nothing planned this week." in a paragraph
of its own; now the frame says it, for any panel that ends up with nothing to show.
