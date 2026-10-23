---
title: The planner keeps its sessions
version: 1
---

**The planner now keeps a copy of its sessions in the browser, saved by a watcher every time the list
is replaced, and reads that copy back instead of the file when one exists.** Nothing in the planner
changes the sessions yet; lesson 5 ticks them off and lesson 14 adds new ones. This lesson puts the
saving in place first, so that from then on nothing typed is lost on a reload.

Saving is the textbook side effect: it writes to something outside the component, `localStorage`,
which `javascript` lesson 18 introduced, and the screen does not change because of it.

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed, watch } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport { weekStart, addDays, formatDay, weekTotal } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')\nconst source = ref('')\nconst monday = ref(weekStart(new Date()))\n\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)", "note": "`watch` joins the imports, and `source` is a new ref that says where the sessions came from."},
 {"code": "const STORAGE_KEY = 'planner.sessions'", "note": "The key the copy is stored under. Prefixing it with the application's name keeps it apart from anything else on the same address."},
 {"code": "fetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    const saved = localStorage.getItem(STORAGE_KEY)\n    sessions.value = saved ? JSON.parse(saved) : data.sessions\n    source.value = saved ? 'this browser' : 'courses.json'\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })", "note": "The courses always come from the file. The sessions come from the browser's copy if there is one, and from the file the first time."},
 {"code": "// Every time the list of sessions is replaced, this browser keeps a copy.\nwatch(sessions, (list) => {\n  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n})\n</script>", "note": "The watcher. It is shallow, and that is enough: the planner's rules replace the list rather than changing it, so every change is a new `.value`."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>\n    <p v-if=\"source\">{{ sessions.length }} sessions, read from {{ source }}</p>\n    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>\n  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in perCourse\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>{{ course.done }} of {{ course.planned }} minutes done, goal {{ course.goal }}</p>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>\n\n<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "The template is lesson 3's with one more line, saying how many sessions there are and where they were read from."}
]}
```

`look` opens a fresh browser every time, with nothing stored, so to see the copy at work it has to load
the page twice in the same browser. `goto /` does that:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'goto /' --text header
[vite] connecting...
[vite] connected.
-- goto /
[vite] connecting...
[vite] connected.
== the text of header
Study planner

Week of 19 October 2026: 75 of 195 minutes done

6 sessions, read from this browser

Previous weekNext week
```

The first visit read the file, and the watcher saved the list the moment it was assigned. **The
second visit read the browser's copy**, which is the line the header prints. In your own browser the
copy stays until you clear the site's data; the browser's developer tools show it under Application,
Local Storage, `http://localhost:5173`, as the key `planner.sessions`.

## Why the watcher can be shallow

Lesson 3's rules return new arrays: `toggleDone` and `addSession` never change the list they are
given. So every change the planner will ever make is an assignment to `sessions.value`, which a plain
watcher sees. If the planner pushed into the array instead, this watcher would miss every change, as
the demo of `deep` did, and the copy would quietly fall behind. **The rule in the plain functions and
the shallow watcher are one decision**, made twice.

## What it does not handle yet

Two things are left honest rather than solved:

- **The file changing.** If `courses.json` gains a session, a browser with a saved copy never sees it,
  because the copy wins. For a planner whose sessions belong to the student, that is the right answer;
  the file is only where a new student starts.
- **A copy that is not valid JSON.** `JSON.parse` would throw, and the error would land in the `catch`
  and say the courses could not be loaded, which is close enough to true. Lesson 13 moves the saving
  into a store, where it gets a proper home.
