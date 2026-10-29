---
title: Types for the rules, and for props
version: 1
---

**A type describes the shape of a value, and the planner has two shapes everybody else depends on: a
course and a session.** Written once, in `planner.ts`, they are used by the rules, the store and the
components, so a misspelt property or a number passed where a string belongs is found by the checker
instead of by a student.

## planner.ts

Lesson 3's rules, the same functions with their parameters and results described:

```typescript
// src/planner.ts: the planner's rules, as plain functions over plain data.
// Nothing here knows about Vue, the page or the clock, which is what makes
// every function testable on its own (lesson 21 does it).

export interface Course {
  id: string
  title: string
  goal: number // minutes a week
}

export interface Session {
  id: string
  course: string // a Course's id
  date: string // YYYY-MM-DD
  minutes: number
  done: boolean
}

export interface Totals {
  planned: number
  done: number
}

// A date as YYYY-MM-DD, in the computer's own time zone.
export function isoDate(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

// The date n days after a YYYY-MM-DD date (before it, if n is negative).
export function addDays(iso: string, n: number): string {
  const [y, m, d] = iso.split('-').map(Number)
  return isoDate(new Date(y, m - 1, d + n))
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function weekStart(date: Date): string {
  const daysSinceMonday = (date.getDay() + 6) % 7
  return addDays(isoDate(date), -daysSinceMonday)
}

// "19 October 2026", for people.
export function formatDay(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(y, m - 1, d).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
}

// The sessions from Monday to Sunday of the week that starts on monday.
export function sessionsInWeek(sessions: Session[], monday: string): Session[] {
  const sunday = addDays(monday, 6)
  return sessions.filter((s) => s.date >= monday && s.date <= sunday)
}

// Minutes planned and minutes done in that week.
export function weekTotal(sessions: Session[], monday: string): Totals {
  const week = sessionsInWeek(sessions, monday)
  return {
    planned: week.reduce((sum, s) => sum + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
  }
}

// A new list with one more session in it. The id is one past the highest.
export function addSession(sessions: Session[], { course, date, minutes }: Omit<Session, 'id' | 'done'>): Session[] {
  const highest = Math.max(0, ...sessions.map((s) => Number(s.id.slice(1))))
  return [...sessions, { id: `s${highest + 1}`, course, date, minutes, done: false }]
}

// A new list in which one session's done flag is flipped.
export function toggleDone(sessions: Session[], id: string): Session[] {
  return sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s))
}
```

`interface Course` and `interface Session` are the planner's data written as types, and every field of
`courses.json` is in them. Each function now says what it takes and gives: `weekTotal(sessions:
Session[], monday: string): Totals`. Two details show what the types are for:

- **`Omit<Session, 'id' | 'done'>`**, the argument of `addSession`, is "a session without the two fields
  the rule fills in", so a caller cannot pass an id of its own, and a new field added to `Session` later
  is required here at once.
- **`Totals`** names what `weekTotal` returns, so a component that reads `total.planned` is checked
  too, and one that reads `total.plan` is told so.

## Props, by type

Lesson 6 declared props with objects that Vue checks while the app runs: `{ type: Number, required:
true }`. With TypeScript, `defineProps` can take a **type** instead, and the compiler turns it into the
same runtime declaration for you. `CourseCard`, with its props as a type:

```html
<!-- src/components/CourseCard.vue -->
<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

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

`planned?: number` is an optional prop; `planned = 0` in the destructuring is its default, the Vue 3.5
form lesson 6 used. And `SessionRow`, whose `session` prop is now a `Session`, not just "an object":

```html
<!-- src/components/SessionRow.vue -->
<script setup lang="ts">
import { computed } from 'vue'
import { formatDay, type Session } from '../planner.js'
import { usePlannerStore } from '../stores/planner.js'

const { session, today = false } = defineProps<{
  session: Session
  today?: boolean
}>()
const emit = defineEmits<{
  toggle: [id: string]
}>()

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

`session: Session` means the template's `session.minutes` and `session.date` are known to exist, and
`session.minuets` would be an error before the page ever opened. The runtime check Vue generates from the
type is `Object`, because a type like `Session` exists only for the checker: at run time, Vue can only
see that it received an object.

Both styles are valid TypeScript, and the planner's other components keep their runtime declarations:
the checker reads those too, and infers the types from them. **The type-based form is the one to write
in new TypeScript code**, because it can describe what an object declaration cannot, such as the shape
of a `Session`.
