---
title: Nested routes, a page inside a page
version: 1
---

**A route can have children, drawn in a `<RouterView>` inside the parent's component.** The course page
keeps its heading and its goal, and below them shows one of two lists: this week's sessions of the
course, or all of them. The part of the page that stays is the parent; the part that changes is a
child.

In `router.js` the course route has `children`, each with a path relative to the parent's:
`''` is `/courses/:id` itself, and `'all'` is `/courses/:id/all`. In `CourseView`, a second
`<RouterView :course="id" />` is where the child is drawn, and it passes the course on as a prop. The two
children:

```html
<!-- src/views/CourseWeek.vue -->
<script setup>
import { computed, inject } from 'vue'
import SessionRow from '../components/SessionRow.vue'
import { plannerKey } from '../keys.js'
import { weekStart, sessionsInWeek } from '../planner.js'

const { course } = defineProps({ course: { type: String, required: true } })
const { sessions, today, toggle } = inject(plannerKey)

const mine = computed(() =>
  sessionsInWeek(
    sessions.value.filter((s) => s.course === course),
    weekStart(new Date()),
  ),
)
</script>

<template>
  <ul v-if="mine.length > 0">
    <SessionRow v-for="s in mine" :key="s.id" :session="s" :today="s.date === today" @toggle="toggle" />
  </ul>
  <p v-else>Nothing planned this week.</p>
</template>
```

```html
<!-- src/views/CourseAll.vue -->
<script setup>
import { computed, inject } from 'vue'
import SessionRow from '../components/SessionRow.vue'
import { plannerKey } from '../keys.js'

const { course } = defineProps({ course: { type: String, required: true } })
const { sessions, today, toggle } = inject(plannerKey)

const mine = computed(() =>
  sessions.value.filter((s) => s.course === course).toSorted((a, b) => a.date.localeCompare(b.date)),
)
</script>

<template>
  <ul>
    <SessionRow v-for="s in mine" :key="s.id" :session="s" :today="s.date === today" @toggle="toggle" />
  </ul>
</template>
```

Straight to the second child, by its address:

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/spanish/all --clock 2026-10-21T10:00 --text main
[vite] connecting...
[vite] connected.
== the text of main
Spanish

Goal: 120 minutes a week

This week · All sessions
 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

Spanish has two sessions, both this week, so both lists show the same two today; Statistics, with its
session of 12 October, is the one where they differ. The links between them are
`<RouterLink :to="{ name: 'course-week', params: { id } }">`, by **name** rather than by path, so that
renaming `all` to `everything` one day changes the route and nothing else.

## The active link

`<RouterLink>` adds the class `router-link-active` to a link whose route is part of the current one, and
`router-link-exact-active` when it is exactly the current one. `CourseView`'s scoped style makes the
exact one bold, which tells a sighted student which list they are on. For a screen reader the router
also sets `aria-current="page"` on the exact one, which announces it as the current page, with nothing
written by you.

```
ana@dev:~/vue/planner$ look http://localhost:5173/courses/spanish/all --html 'nav[aria-label=Sessions]' --text -
[vite] connecting...
[vite] connected.
== the HTML of nav[aria-label=Sessions]
<nav data-v-62175599="" aria-label="Sessions"><a data-v-62175599="" href="/courses/spanish" class="router-link-active">This week</a> · <a data-v-62175599="" aria-current="page" href="/courses/spanish/all" class="router-link-active router-link-exact-active">All sessions</a></nav>
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The address /courses/spanish/all, split into its parts, and the boxes each part fills. App draws the header, the footer and a RouterView. The path /courses/spanish matches the course route, whose CourseView fills App&#x27;s RouterView and has a RouterView of its own. The last segment, all, matches the child route, whose CourseAll fills CourseView&#x27;s RouterView.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">/courses/spanish</text><text x=\"156\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">/all</text><rect x=\"20\" y=\"40\" width=\"680\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">App.vue: header and footer on every page</text><rect x=\"40\" y=\"68\" width=\"640\" height=\"158\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"50\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;RouterView&gt;  →  CourseView</text><text x=\"50\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanish · goal: 120 minutes a week</text><rect x=\"60\" y=\"120\" width=\"600\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"70\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;RouterView&gt;  →  CourseAll</text><text x=\"70\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">19 October 2026, Spanish, 30 minutes</text><text x=\"70\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">23 October 2026, Spanish, 40 minutes</text></svg>", "caption": "Each RouterView draws one level of the matched route: the parent's level inside App, the child's inside the parent."}
```

## When to nest

Nest when part of the screen stays and part changes with the address: tabs of a page, the steps of a
form, a list with the selected item beside it. Do not nest only because the paths look nested: a
route at `/courses/spanish/all` can be a top-level route with its own whole page, if nothing of the
course page needs to stay around it.
