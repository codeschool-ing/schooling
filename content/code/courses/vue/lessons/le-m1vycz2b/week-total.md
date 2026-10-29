---
title: The planner adds up the week
version: 1
---

**The planner now shows one week at a time, with the minutes planned and done in it, for the whole
plan and for each course, all of it computed.** The only new state is the Monday of the week being
shown; everything on the screen is worked out from that and from the sessions.

## The rules, apart from Vue

The arithmetic of a week has nothing to do with Vue, so it goes in a file of plain functions that know
nothing about refs. Save this as `src/planner.js`:

```javascript
// src/planner.js: the planner's rules, as plain functions over plain data.
// Nothing here knows about Vue, the page or the clock, which is what makes
// every function testable on its own (lesson 21 does it).

// A date as YYYY-MM-DD, in the computer's own time zone.
export function isoDate(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

// The date n days after a YYYY-MM-DD date (before it, if n is negative).
export function addDays(iso, n) {
  const [y, m, d] = iso.split('-').map(Number)
  return isoDate(new Date(y, m - 1, d + n))
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function weekStart(date) {
  const daysSinceMonday = (date.getDay() + 6) % 7
  return addDays(isoDate(date), -daysSinceMonday)
}

// "19 October 2026", for people.
export function formatDay(iso) {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(y, m - 1, d).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
}

// The sessions from Monday to Sunday of the week that starts on monday.
export function sessionsInWeek(sessions, monday) {
  const sunday = addDays(monday, 6)
  return sessions.filter((s) => s.date >= monday && s.date <= sunday)
}

// Minutes planned and minutes done in that week.
export function weekTotal(sessions, monday) {
  const week = sessionsInWeek(sessions, monday)
  return {
    planned: week.reduce((sum, s) => sum + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
  }
}

// A new list with one more session in it. The id is one past the highest.
export function addSession(sessions, { course, date, minutes }) {
  const highest = Math.max(0, ...sessions.map((s) => Number(s.id.slice(1))))
  return [...sessions, { id: `s${highest + 1}`, course, date, minutes, done: false }]
}

// A new list in which one session's done flag is flipped.
export function toggleDone(sessions, id) {
  return sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s))
}
```

Two of those functions, `addSession` and `toggleDone`, are not used yet: lesson 5 ticks sessions off
with `toggleDone`, and lesson 14 adds them with `addSession`. They are here so that the file of rules
is written once, whole.

**None of them changes what it is given.** `addSession` returns a new array; `toggleDone` returns a new
array with a new object for the session that changed. That is the same rule the last section gave for
a computed, and for the same reason: a function that only reads its input can be called from anywhere,
including from inside a computed, without surprises.

Dates are strings in `YYYY-MM-DD` because that form sorts correctly as text, so `s.date >= monday` is a
date comparison with no `Date` objects involved. `Date` appears only where a date has to be built or
shown, and always in the computer's own time zone, so a session on the 19th is on the 19th wherever the
planner is opened.

## The component

`App.vue` gains the Monday, the computed totals and two buttons:

```schooling-example
{"language": "html", "file": "src/App.vue", "parts": [
 {"code": "<script setup>\nimport { ref, computed } from 'vue'\nimport AppFooter from './components/AppFooter.vue'\nimport { weekStart, addDays, formatDay, weekTotal } from './planner.js'\n\nconst title = 'Study planner'\nconst courses = ref([])\nconst sessions = ref([])\nconst error = ref('')", "note": "The new imports: `computed`, and four of the planner's rules."},
 {"code": "const monday = ref(weekStart(new Date()))", "note": "The one new piece of state: the Monday of the week on screen, starting with this week's."},
 {"code": "\nconst total = computed(() => weekTotal(sessions.value, monday.value))\nconst perCourse = computed(() =>\n  courses.value.map((course) => ({\n    ...course,\n    ...weekTotal(\n      sessions.value.filter((s) => s.course === course.id),\n      monday.value,\n    ),\n  })),\n)", "note": "Two computed values. `total` is the whole week; `perCourse` is each course with its own totals added, made by calling the same rule on that course's sessions."},
 {"code": "fetch('/courses.json')\n  .then((response) => {\n    if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n    return response.json()\n  })\n  .then((data) => {\n    courses.value = data.courses\n    sessions.value = data.sessions\n  })\n  .catch((e) => {\n    error.value = `Could not load the courses: ${e.message}`\n  })\n</script>", "note": "Loading is unchanged from lesson 2."},
 {"code": "<template>\n  <header>\n    <h1>{{ title }}</h1>\n    <p v-if=\"error\" role=\"alert\">{{ error }}</p>\n    <p v-else-if=\"courses.length === 0\">Loading…</p>\n    <p v-else>\n      Week of {{ formatDay(monday) }}: {{ total.done }} of {{ total.planned }} minutes done\n    </p>", "note": "The header says which week it is and how much is done. `formatDay` is called in the template because it only formats."},
 {"code": "    <nav>\n      <button @click=\"monday = addDays(monday, -7)\">Previous week</button>\n      <button @click=\"monday = addDays(monday, 7)\">Next week</button>\n    </nav>\n  </header>", "note": "Each button replaces `monday`, and both computed values follow."},
 {"code": "  <main>\n    <ul class=\"courses\">\n      <li v-for=\"course in perCourse\" :key=\"course.id\">\n        <h2>{{ course.title }}</h2>\n        <p>{{ course.done }} of {{ course.planned }} minutes done, goal {{ course.goal }}</p>\n      </li>\n    </ul>\n  </main>\n  <AppFooter />\n</template>\n\n<style scoped>\nheader {\n  border-bottom: 2px solid #2f6f4e;\n}\np {\n  color: #2f6f4e;\n}\n.courses {\n  list-style: none;\n  padding: 0;\n}\n</style>", "note": "The list draws `perCourse` instead of `courses`."}
]}
```

The planner's dev server is running in the second terminal. The browser's clock decides which week
comes first, so every transcript in this course sets it to Wednesday, 21 October 2026, with `--clock`:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00
[vite] connecting...
[vite] connected.
== the text of #app
Study planner

Week of 19 October 2026: 75 of 195 minutes done

Previous weekNext week
Statistics

45 of 105 minutes done, goal 180

Spanish

30 of 70 minutes done, goal 120

Guitar

0 of 20 minutes done, goal 90

Built with Vue 3.5.44
```

**75 of 195** is the five sessions of the week of 19 October: 45, 30, 60, 20 and 40 minutes planned,
the first two done. The session of the 12th is not in it. One week back:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Previous week' --text header
[vite] connecting...
[vite] connected.
-- click text=Previous week
== the text of header
Study planner

Week of 12 October 2026: 50 of 50 minutes done

Previous weekNext week
```

`text=Previous week` is how Playwright, and so `look`, finds a button by what it says. The week of 12
October holds one session, 50 minutes, done.

## Where the numbers come from

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The planner&#x27;s dependency graph. Three refs on the left: courses, sessions and monday. Two computed values in the middle: total reads sessions and monday, and perCourse reads all three refs. The template on the right reads total, perCourse and monday. A click on Previous week writes monday; the arrows from monday mark total, perCourse and the template stale, and the redraw recomputes each once.\"><text x=\"95\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">owned: ref</text><text x=\"365\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">derived: computed</text><text x=\"625\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">drawn</text><rect x=\"30\" y=\"42\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">courses</text><rect x=\"30\" y=\"97\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sessions</text><rect x=\"30\" y=\"152\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">monday</text><rect x=\"300\" y=\"67\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">total</text><rect x=\"300\" y=\"132\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">perCourse</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;template&gt;</text><line x1=\"162\" y1=\"115\" x2=\"298\" y2=\"85\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,85.0 291.5,89.6 290.1,83.5\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"170\" x2=\"298\" y2=\"85\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,85.0 293.4,91.5 290.1,86.3\" fill=\"var(--amber)\"></polygon><line x1=\"162\" y1=\"60\" x2=\"298\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,150.0 290.1,148.5 293.6,143.3\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"115\" x2=\"298\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,150.0 290.1,151.2 291.6,145.1\" fill=\"var(--wire)\"></polygon><line x1=\"162\" y1=\"170\" x2=\"298\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,150.0 291.2,154.2 290.3,148.0\" fill=\"var(--amber)\"></polygon><line x1=\"432\" y1=\"85\" x2=\"558\" y2=\"85\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,85.0 550.6,88.1 550.6,81.9\" fill=\"var(--phosphor-dim)\"></polygon><line x1=\"432\" y1=\"150\" x2=\"558\" y2=\"140\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,140.0 550.9,143.7 550.4,137.5\" fill=\"var(--phosphor-dim)\"></polygon><path d=\"M162,180 C300,215 500,215 600,182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"598\" y1=\"186\" x2=\"602\" y2=\"181\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"602.0,181.0 599.8,188.7 595.0,184.8\" fill=\"var(--amber)\"></polygon><text x=\"365\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the template reads monday too</text></svg>", "caption": "Nobody wrote these arrows. Each one was recorded when a computed or the template read a value."}
```

Follow one click. `monday` is replaced. `total` and `perCourse` both read `monday.value` when they last
ran, so both are marked stale. The template read both, so it is queued to redraw (lesson 2's queue).
The redraw reads `total` and `perCourse`, which run their functions again, once each. **Nothing in the
code says "when the week changes, recompute the totals"**: the dependency was recorded when the
functions read the Monday, and that is the whole mechanism.

Guitar shows 0 of 20 minutes against a goal of 90, which is honest and a little alarming. Lesson 5 lets
you tick the session off.
