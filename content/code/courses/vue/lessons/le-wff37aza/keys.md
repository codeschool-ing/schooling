---
title: Keys, the name the data goes by
version: 1
---

**Every `useFetch` and `useAsyncData` stores its data under a key, and the key decides three things:
where the payload keeps the answer, which calls share it, and when it is fetched again.** `useFetch`
makes the key from the URL and the options; `useAsyncData` takes it as its first argument.

The course page shows the key at work. It fetched the whole planner and kept one course of it, which
put every course's sessions into every course page's payload. A route for one course fixes that:

```typescript
// server/api/courses/[id].get.ts: GET /api/courses/spanish, one course and its sessions.
export default defineEventHandler((event) => {
  const id = getRouterParam(event, 'id')
  const course = planner.courses.find((c) => c.id === id)
  if (!course) {
    throw createError({ statusCode: 404, statusMessage: `No course called ${id}` })
  }
  return { course, sessions: planner.sessions.filter((s) => s.course === id) }
})
```

and the page asks for it with a URL that is a function of the route:

```html
<!-- app/pages/courses/[id].vue: one course, at /courses/statistics and the like -->
<script setup lang="ts">
const route = useRoute()
const { data, error, refresh } = await useFetch(() => `/api/courses/${route.params.id}`)
if (error.value) {
  throw createError({ statusCode: error.value.statusCode, statusMessage: error.value.statusMessage })
}
const sessions = computed(() =>
  (data.value?.sessions ?? []).toSorted((a, b) => a.date.localeCompare(b.date)),
)

async function toggle(id: string) {
  await $fetch(`/api/sessions/${id}`, { method: 'PATCH' })
  await refresh()
}
</script>

<template>
  <h1>{{ data?.course.title }}</h1>
  <p>Goal: {{ data?.course.goal }} minutes a week</p>
  <ul>
    <SessionRow
      v-for="s in sessions"
      :key="s.id"
      :session="s"
      :title="data?.course.title ?? s.course"
      @toggle="toggle"
    />
  </ul>
</template>
```

**A function for the URL makes the key reactive**: when the route's `id` changes, the URL changes, and
so does the key, and `useFetch` fetches the new course by itself. Visit two courses, one after the
other, inside one page:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --do 'click text=Spanish' --do 'click .brand a' --do 'click text=Guitar' --text main | grep '/api/\|^-- '
-- click text=Spanish
net  GET /api/courses/spanish  200
-- click .brand a
net  GET /api/courses  200
-- click text=Guitar
net  GET /api/courses/guitar  200
```

One request per page shown, each to its own address. The week, visited in between, asked too: its data
came with the page when the page was first loaded, and a navigation back to it runs its `useFetch` in
the browser, under the week's own key.

## One key, two meanings

A key that two calls share is one piece of data, which is the point when both mean the same thing,
and a bug when they do not. Two `useAsyncData` calls named alike, in a page made for it:

```html
<!-- app/pages/demo/clash.vue: two different things under one key -->
<script setup lang="ts">
const { data: count } = await useAsyncData('planner', () =>
  $fetch('/api/courses').then((planner) => planner.sessions.length),
)
const { data: planner } = await useAsyncData('planner', () => $fetch('/api/courses'))
</script>

<template>
  <p>{{ count }} sessions in {{ planner?.courses?.length }} courses</p>
</template>
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/demo/clash --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
[warn] [NUXT_E3004] Incompatible options detected for "planner":
- different handler
├▶ fix: You can use a different key or move the call to a composable to ensure the options are shared across calls.
╰▶ sources: http://localhost:3000/_nuxt/pages/demo/clash.vue:10:76
== the text of main
6 sessions in courses
```

**`NUXT_E3004`, and a page with a hole in it.** The second call found the key taken by a different
function, warned, and got the first call's data, a number, which has no `courses`. Keys written by hand
need to be names nobody else will choose, and the safest way to get that is one composable per
piece of data, `useSessionCount()`, so the key is written once. Delete the demo:

```
ana@dev:~/vue/planner-nuxt$ rm -r app/pages/demo
```
