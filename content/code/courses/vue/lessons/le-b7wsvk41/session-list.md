---
title: The planner's list of the week
version: 1
---

**The planner now lists the week's sessions under the courses, in date order, each with a checkbox
that marks it done, and the totals follow.** Every directive of this lesson is in it: `v-for` with a
real key, `v-if` and `v-else` for an empty week, `:class` for a session that is done, and a checkbox
bound by hand rather than by `v-model`.

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport { weekStart, addDays, formatDay, weekTotal, sessionsInWeek, toggleDone } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))", "note": "Two more of the planner's rules are imported: `sessionsInWeek` and `toggleDone`."},
 {"code": "const thisWeek = computed(() =>\n  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),\n)\nconst titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))", "note": "The week's sessions, sorted by date with `toSorted`, which leaves the list alone (lesson 3). `titles` maps a course id to its title, so a row can show \"Statistics\" for `statistics`."},
 {"code": "function toggle(id) {\n  sessions.value = toggleDone(sessions.value, id)\n}", "note": "Ticking a box replaces the list with a new one from the rules. The watcher of lesson 4 sees the new list and saves it."},
 {"code": "const perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)\n\nconst STORAGE_KEY = 'planner.sessions'\n\nfetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n\n// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>\n\n<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>\n  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in perCourse\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>{{ course.done }} of {{ course.planned }} minutes done, goal {{ course.goal }}</p>\n      </li>\n    </ul>", "note": "The rest of the script, and the header, are lesson 4's."},
 {"code": "    <h2>This week</h2>\n    <p v-if=\"thisWeek.length === 0\">Nothing planned this week.</p>\n    <ul v-else class=\"sessions\">\n      <li v-for=\"session in thisWeek\" :key=\"session.id\" :class=\"{ done: session.done }\">\n        <label>\n          <input type=\"checkbox\" :checked=\"session.done\" @change=\"toggle(session.id)\" />\n          {{ formatDay(session.date) }}, {{ titles[session.course] }}, {{ session.minutes }} minutes\n        </label>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>", "note": "The new list. `:checked` shows the state; `@change` asks for the change. Together they are what `v-model` would have written, routed through `toggle`."},
 {"code": "<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses,\n.sessions {\n  list-style: none;\n  padding: 0;\n}\n.done {\n  text-decoration: line-through;\n}\n</style>", "note": "`.sessions` shares the list style, and a session that is done is struck through."}
]}
```

With the planner's dev server running, tick the guitar session and load the page again:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'check label:has-text("Guitar") input' --do 'goto /' --text main
[vite] connecting...
[vite] connected.
-- check label:has-text("Guitar") input
-- goto /
[vite] connecting...
[vite] connected.
== the text of main
Statistics

45 of 105 minutes done, goal 180

Spanish

30 of 70 minutes done, goal 120

Guitar

20 of 20 minutes done, goal 90

This week
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

`label:has-text("Guitar") input` finds the checkbox inside the label that mentions Guitar, which is how
a person would find it too. **After the reload, guitar shows 20 of 20 minutes**: the tick replaced the
list, lesson 4's watcher saved it, and the second visit read it back from the browser. The checkbox
itself does not appear in the text, which is why the totals are the evidence.

## Why the checkbox is inside a label

Clicking the words ticks the box, which is a bigger target for a finger, and a screen reader
announces the box with the words as its name: *"19 October 2026, Statistics, 45 minutes, checkbox,
checked"*. A checkbox with its text beside it but not inside a label, or not tied to it with `for` and
`id`, is announced as *"checkbox, checked"* and nothing else. The `look` selector above found the box
through its label for the same reason a screen reader does.

## The keys, once more

`:key="session.id"`. Tick a session, and the list is replaced by a new array, with a new object for that
session, but the ids are the same, so Vue keeps every `<li>` and only updates the one whose `done`
changed. Sorted by date, the same session can move position when one is added in lesson 14, and its row
moves with it. That is the behaviour the last two sections were about, arriving for free because the
data carries ids.
