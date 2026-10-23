---
title: Parameters, a course per address
version: 1
---

**A segment of a path written as `:id` is a parameter: it matches whatever is in that position and
hands it to the view.** `/courses/:id` matches `/courses/spanish` and `/courses/guitar`, and the view
learns which with `id` set to `spanish` or `guitar`. One route, one component, as many pages as there
are courses.

```html
<!-- src/views/CourseView.vue -->
<script setup>
import { computed, inject } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { plannerKey } from '../keys.js'

// The route's :id arrives as a prop, because the route says `props: true`.
const { id } = defineProps({ id: { type: String, required: true } })
const { courses } = inject(plannerKey)

const course = computed(() => courses.value.find((c) => c.id === id))
</script>

<template>
  <h1>{{ course?.title ?? id }}</h1>
  <p v-if="course">Goal: {{ course.goal }} minutes a week</p>
  <nav aria-label="Sessions">
    <RouterLink :to="{ name: 'course-week', params: { id } }">This week</RouterLink> ·
    <RouterLink :to="{ name: 'course-all', params: { id } }">All sessions</RouterLink>
  </nav>
  <RouterView :course="id" />
</template>

<style scoped>
.router-link-exact-active {
  font-weight: 700;
}
</style>
```

Open the week and click the first link that says Spanish, which is the course card's title:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Spanish >> nth=0' --text main
[vite] connecting...
[vite] connected.
-- click text=Spanish >> nth=0
== the text of main
Spanish

Goal: 120 minutes a week

This week · All sessions
 19 October 2026, Spanish, 30 minutes
 23 October 2026, Spanish, 40 minutes
```

`text=Spanish >> nth=0` is Playwright's way to say "the first element whose text is Spanish". The page
changed to the course without a reload: the header and footer stayed, and only what is inside
`<RouterView>` was replaced.

## Two ways to read a parameter

The route says `props: true`, so the router passes `params.id` to the view **as a prop**, and the view
declares it like any prop. The other way is to ask the router:

```javascript
import { useRoute } from 'vue-router'
const route = useRoute()
// route.params.id, route.query, route.path, route.name, route.meta
```

**Prefer the prop.** A view that takes `id` as a prop can be used, and tested in lesson 21, by giving it
an `id`; a view that calls `useRoute()` needs a whole router around it to work at all. `useRoute()` is
right for what is not a parameter, like the query string, or for the page that is about the address
itself, as `NotFound` is in the section on guards.

## The same view, a new parameter

Go from `/courses/spanish` to `/courses/guitar` and the router does not destroy `CourseView` and make a
new one: the route is the same, so it **reuses the component and changes the prop**. That is fast, and
it means any code that ran once in setup with the old `id` does not run again. `CourseView` is written
for it: `course` is a `computed` of `id`, so it follows. A view that fetched its course's data once, in
setup, would go on showing Spanish under a Guitar address. If a view must react to the change, watch
the prop, `watch(() => id, …)`, lesson 4's getter form, or use `onBeforeRouteUpdate` from Vue Router.
